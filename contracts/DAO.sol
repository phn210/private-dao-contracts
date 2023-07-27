pragma solidity ^0.8.0;

import "./interfaces/IDAO.sol";
import "./interfaces/IDKG.sol";
import "./interfaces/IDKGRequest.sol";
import "./libs/Math.sol";
import "./libs/MerkleTree.sol";
import "./FundManager.sol";

contract DAO is IDAO, IDKGRequest, AutomationCompatibleInterface {
    uint256 internal constant Q =
        0x30644E72E131A029B85045B68181585D2833E84879B9709143E1F593F0000001;

    // descriptionHash
    bytes32 public descriptionHash;

    // Number
    uint256 internal constant VOTE_OPTIONS = 3;

    // Configuration for governor processes.
    Config public config;

    //
    FundManager private fundManager;

    // The address of the DKG contract.
    IDKG private dkg;

    // Number of proposal created
    uint256 public proposalCounter;

    // Public key for vote encryption
    uint256 private distributedKeyID;

    // Index of proposals' ID.
    mapping(uint256 => uint256) public proposalIDs;

    // Record of all proposals ever proposed.
    mapping(uint256 => Proposal) public proposals;

    // Record of DKG request of proposals
    mapping(bytes32 => Request) public requests;

    mapping(uint256 => Action[]) public actions;

    mapping(uint256 => bytes32) public descriptions;

    // Record of nullifier hashes of proposals for preventing double-voting
    mapping(uint256 => mapping(uint256 => bool)) private nullifierHashes;

    // Queue for timelock
    mapping(bytes32 => bool) private queuedTransactions;

    /**
     * =====================
     * ===== MODIFIERS =====
     * =====================
     */

    modifier onlyDAO() {
        require(
            msg.sender == address(this),
            "DAO::onlyDAO: call must come from the DAO contract itself"
        );
        _;
    }

    modifier onlyDKG() override {
        require(
            msg.sender == address(dkg),
            "DAO::onlyDKG: call must come from the DKG contract"
        );
        _;
    }

    /**
     * =====================
     * ===== FUNCTIONS =====
     * =====================
     */

    constructor(
        Config memory _config,
        address _fundManager,
        address _dkg,
        uint256 _distributedKeyID,
        bytes32 _descriptionHash
    ) {
        config = _config;
        fundManager = FundManager(_fundManager);
        dkg = IDKG(_dkg);
        distributedKeyID = _distributedKeyID;
        descriptionHash = _descriptionHash;
    }

    /**
     * =========================
     * ===== DAO FUNCTIONs =====
     * =========================
     */

    /**
     * Propose a new proposal with special requirements for proposer.
     * @param _actions Proposal's actions
     * @param _descriptionHash IPFS hash of proposal's description
     * @return Proposal's index
     */
    function propose(
        Action[] calldata _actions,
        bytes32 _descriptionHash
    ) external override returns (uint256) {
        uint256 proposalID = hashProposal(_actions, _descriptionHash);
        proposalIDs[proposalCounter] = proposalID;
        Proposal storage newProposal = proposals[proposalID];

        // Check new proposal has  not exist
        require(
            newProposal.startBlock == 0,
            "DAO::propose: proposal already existed"
        );

        // Check vote encryption key is usable and dkg type is correct
        require(
            dkg.getDistributedKeyState(distributedKeyID) ==
                IDKG.DistributedKeyState.ACTIVE &&
                dkg.getType(distributedKeyID) == IDKG.DistributedKeyType.VOTING
        );

        // Check vote encryption key's verifier has the correct dimenstion
        uint8 dimension = dkg.getDimension(distributedKeyID);
        require(
            dimension == VOTE_OPTIONS,
            "DAO::propose: can not use distributed key with the wrong dimension"
        );

        // Assign proposal's data
        uint64 startBlock = uint64(block.number + config.pendingPeriod);

        newProposal.proposalID = proposalID;
        newProposal.proposer = msg.sender;
        newProposal.startBlock = startBlock;

        Action[] storage proposalActions = actions[proposalID];
        // proposalActions.push(_actions);
        descriptions[proposalID] = _descriptionHash;

        bytes32 requestID = getRequestID(
            distributedKeyID,
            address(this),
            proposalID
        );

        // Assign dkg request data for this proposal
        newProposal.requestID = requestID;
        Request storage request = requests[requestID];
        request.distributedKeyID = distributedKeyID;
        for (uint8 i; i < dimension; i++) {
            request.R.push([0, 1]);
            request.M.push([0, 1]);
        }

        emit ProposalCreated(
            proposalCounter,
            proposalID,
            msg.sender,
            _actions,
            startBlock,
            _descriptionHash
        );

        // Increase proposal counter
        ++proposalCounter;

        return proposalCounter;
    }

    function castVote(
        uint256 _proposalID,
        VoteData calldata _voteData
    ) external override {
        Proposal storage proposal = proposals[_proposalID];

        require(
            state(_proposalID) == ProposalState.Active,
            "DAO::CastVote: Proposal is not in the voting period"
        );

        require(
            !nullifierHashes[_proposalID][_voteData.nullifierHash],
            "DAO::CastVote: Double voting is not allowed"
        );

        require(
            fundManager.isKnownRoot(_voteData.root),
            "DAO::CastVote: Root is invalid"
        );

        nullifierHashes[_proposalID][_voteData.nullifierHash] = true;

        Request storage request = requests[proposal.requestID];

        uint8 dimension = dkg.getDimension(request.distributedKeyID);
        require(
            _voteData._R.length == dimension &&
                _voteData._M.length == dimension,
            "FundManager: invalid input length"
        );

        IVerifier verifier = dkg.getVerifier(request.distributedKeyID);
        uint256[] memory publicInputs = new uint256[](
            verifier.getPublicInputsLength()
        );

        publicInputs[0] = _voteData.root;
        publicInputs[1] = (uint256)(uint160(address(this)));
        publicInputs[2] = _proposalID;
        (publicInputs[3], publicInputs[4]) = dkg.getPublicKey(
            request.distributedKeyID
        );
        publicInputs[5] = _voteData.nullifierHash;
        for (uint8 i; i < dimension; i++) {
            publicInputs[6 + 2 * i] = _voteData._R[i][0];
            publicInputs[6 + 2 * i + 1] = _voteData._R[i][1];
            publicInputs[6 + 2 * dimension + 2 * i] = _voteData._M[i][0];
            publicInputs[6 + 2 * dimension + 2 * i + 1] = _voteData._M[i][1];
        }

        require(
            _verifyProof(verifier, _voteData._proof, publicInputs),
            "DAO::CastVote: ZK Proof is invalid"
        );

        for (uint8 i; i < dimension; i++) {
            (request.R[i][0], request.R[i][1]) = CurveBabyJubJub.pointAdd(
                request.R[i][0],
                request.R[i][1],
                _voteData._R[i][0],
                _voteData._R[i][1]
            );
            (request.M[i][0], request.M[i][1]) = CurveBabyJubJub.pointAdd(
                request.M[i][0],
                request.M[i][1],
                _voteData._M[i][0],
                _voteData._M[i][1]
            );
        }

        emit VoteCast(_proposalID, _voteData.nullifierHash);
    }

    /**
     * Tally the result of a proposal.
     * @param _proposalID The id of the proposal to tally
     */
    function tally(uint256 _proposalID) public override {
        require(
            state(_proposalID) == ProposalState.Tallying,
            "DAO::tally: not in the tallying period"
        );

        bytes32 requestID = proposals[_proposalID].requestID;
        Request storage request = requests[requestID];

        dkg.startTallying(
            requestID,
            request.distributedKeyID,
            request.R,
            request.M
        );

        emit ProposalTallyingStarted(_proposalID, requestID);
    }

    function submitTallyResult(
        bytes32 _requestID,
        uint256[] calldata _result
    ) external override onlyDKG {
        Request storage request = requests[_requestID];
        require(
            request.distributedKeyID == distributedKeyID,
            "DAO::submitTallyingResult: request does not exist"
        );
        request.result = _result;
        request.respondedAt = block.number;
    }

    /**
     * Finalize the result of a proposal.
     * @param _proposalID The id of the proposal to finalize
     */
    function finalize(uint256 _proposalID) public override {
        require(
            state(_proposalID) == ProposalState.Tallying,
            "DAO::finalize: not in the tallying period"
        );

        Proposal storage proposal = proposals[_proposalID];
        Request storage request = requests[proposal.requestID];

        require(
            request.respondedAt > 0,
            "DAO::finalize: DKG request has not been responded"
        );

        uint256 forVotes = request.result[uint256(VoteOption.For)];
        uint256 againstVotes = request.result[uint256(VoteOption.Against)];
        uint256 abstainVotes = request.result[uint256(VoteOption.Abstain)];

        proposal.forVotes = forVotes;
        proposal.againstVotes = againstVotes;
        proposal.abstainVotes = abstainVotes;

        emit ProposalFinalized(
            _proposalID,
            forVotes,
            againstVotes,
            abstainVotes
        );
    }

    /**
     * Queue a succeeded proposal. This requires the quorum to be reached, the vote to be successful, and the voting period has ended.
     * @param _proposalID The id of the proposal to queue
     */
    function queue(uint256 _proposalID) public override {
        require(
            state(_proposalID) == ProposalState.Succeeded,
            "DAO::queue: Proposal has not been finalized yet"
        );

        Proposal storage proposal = proposals[_proposalID];
        uint256 eta = block.number + config.timelockPeriod;

        Action[] storage proposalActions = actions[_proposalID];

        for (uint256 i = 0; i < proposalActions.length; i++) {
            _queueTransaction(
                proposalActions[i].target,
                proposalActions[i].value,
                proposalActions[i].signature,
                proposalActions[i].data,
                eta
            );
        }
        proposal.eta = eta;

        emit ProposalQueued(_proposalID, eta);
    }

    /**
     * Execute a succeeded proposal. This requires the quorum to be reached, the vote to be successful, and the timelock delay period has passed.
     * @param _proposalID The id of the proposal to execute
     */
    function execute(uint256 _proposalID) public payable override {
        require(
            state(_proposalID) == ProposalState.Queued,
            "DAO::queue: Proposal has not been queued yet"
        );

        Proposal storage proposal = proposals[_proposalID];
        uint256 eta = proposal.eta;

        Action[] storage proposalActions = actions[_proposalID];

        for (uint256 i = 0; i < proposalActions.length; i++) {
            _executeTransaction(
                proposalActions[i].target,
                proposalActions[i].value,
                proposalActions[i].signature,
                proposalActions[i].data,
                eta
            );
        }
        proposal.executed = true;

        emit ProposalExecuted(_proposalID);
    }

    /**
     * Cancel a queued proposal. This requires the proposer has not been executed yet.
     * @param _proposalID The id of the proposal to cancel
     */
    function cancel(uint256 _proposalID) public override {
        require(
            state(_proposalID) != ProposalState.Executed,
            "DAO::cancel: Cannot cancel executed proposal"
        );
        require(
            state(_proposalID) != ProposalState.Canceled,
            "DAO::cancel: Cannot cancel canceled proposal"
        );

        Proposal storage proposal = proposals[_proposalID];

        proposal.canceled = true;

        Action[] storage proposalActions = actions[_proposalID];

        for (uint256 i = 0; i < proposalActions.length; i++) {
            _cancelTransaction(
                proposalActions[i].target,
                proposalActions[i].value,
                proposalActions[i].signature,
                proposalActions[i].data,
                proposal.eta
            );
        }

        emit ProposalCanceled(_proposalID);
    }

    /**
     * ==========================
     * ===== VIEW FUNCTIONs =====
     * ==========================
     */

    /**
     * Hash a proposal's parameters to get its ID.
     * @param _actions Proposal's actions
     * @param _descriptionHash IPFS hash of proposal's description
     */
    function hashProposal(
        Action[] calldata _actions,
        bytes32 _descriptionHash
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(_actions, _descriptionHash))) % Q;
    }

    /**
     * Gets the status of a proposal.
     * @param _proposalID The id of the proposal
     * @return Proposal's status
     */
    function state(uint256 _proposalID) public view returns (ProposalState) {
        Proposal memory proposal = proposals[_proposalID];
        Request memory request = requests[proposal.requestID];
        require(proposal.startBlock > 0, "DAO::state: proposal not existed.");
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (
            block.number <= (proposal.startBlock + config.votingPeriod)
        ) {
            return ProposalState.Active;
        } else if (
            block.number <=
            (proposal.startBlock + config.votingPeriod + config.tallyingPeriod)
        ) {
            return ProposalState.Tallying;
        } else if (
            proposal.forVotes + proposal.againstVotes + proposal.abstainVotes ==
            0 ||
            request.respondedAt >
            (proposal.startBlock + config.votingPeriod + config.tallyingPeriod)
        ) {
            return ProposalState.Expired;
        } else if (proposal.forVotes <= proposal.againstVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.number >= (proposal.eta + config.queuingPeriod)) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * =================================
     * ===== DKG REQUEST FUNCTIONS =====
     * =================================
     */

    function getRequestID(
        uint256 _distributedKeyID,
        address _requestor,
        uint256 _nonce
    ) public pure override returns (bytes32) {
        return
            keccak256(abi.encodePacked(_distributedKeyID, _requestor, _nonce));
    }

    function getDistributedKeyID(
        bytes32 _requestID
    ) external view override returns (uint256) {
        return requests[_requestID].distributedKeyID;
    }

    function getResult(
        bytes32 _requestID
    ) external view override returns (uint256[] memory) {
        return requests[_requestID].result;
    }

    /**
     * ==============================
     * ===== INTERNAL FUNCTIONS =====
     * ==============================
     */

    function _verifyProof(
        IVerifier _verifier,
        bytes calldata _proof,
        uint256[] memory _publicInputs
    ) internal view returns (bool) {
        require(_publicInputs.length == _verifier.getPublicInputsLength());
        uint256[8] memory proof = abi.decode(_proof, (uint256[8]));
        for (uint8 i = 0; i < proof.length; i++) {
            require(
                proof[i] < Math.PRIME_Q,
                "verifier-proof-element-gte-prime-q"
            );
        }
        return
            _verifier.verifyProof(
                [proof[0], proof[1]],
                [[proof[2], proof[3]], [proof[4], proof[5]]],
                [proof[6], proof[7]],
                _publicInputs
            );
    }

    function _queueTransaction(
        address _target,
        uint _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) internal {
        require(
            _eta >= (block.number + config.timelockPeriod),
            "DAO::_queueTransaction: Estimated execution block must satisfy delay"
        );

        bytes32 txHash = keccak256(
            abi.encode(_target, _value, _signature, _data, _eta)
        );

        require(
            !queuedTransactions[txHash],
            "DAO::_executeTransaction: Transaction has been queued."
        );

        queuedTransactions[txHash] = true;
    }

    function _cancelTransaction(
        address _target,
        uint _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) internal {
        bytes32 txHash = keccak256(
            abi.encode(_target, _value, _signature, _data, _eta)
        );

        queuedTransactions[txHash] = false;
    }

    function _executeTransaction(
        address _target,
        uint _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) internal {
        bytes32 txHash = keccak256(
            abi.encode(_target, _value, _signature, _data, _eta)
        );
        require(
            queuedTransactions[txHash],
            "DAO::_executeTransaction: Transaction hasn't been queued."
        );
        require(
            block.number >= _eta &&
                block.number <= (_eta + config.queuingPeriod),
            "DAO::_executeTransaction: Transaction can not be executed now."
        );

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(_signature).length == 0) {
            callData = _data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(_signature))),
                _data
            );
        }

        (bool success, bytes memory returnData) = _target.call{value: _value}(
            callData
        );
        require(
            success,
            "Timelock::executeTransaction: Transaction execution reverted."
        );
    }

    receive() external payable {}

    /**
     * ================================
     * ===== CHAINLINK AUTOMATION =====
     * ================================
     */

    function checkUpkeep(
        bytes calldata checkData
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256[2] memory rangeToCheck = abi.decode(checkData, (uint256[2]));

        if (
            rangeToCheck[1] >= proposalCounter ||
            rangeToCheck[0] > rangeToCheck[1] ||
            rangeToCheck[0] >= proposalCounter
        ) revert("DAO::checkUpkeep: Invalid range!");

        for (uint256 i = rangeToCheck[0]; i <= rangeToCheck[1]; i++) {
            if (i >= proposalCounter) continue;
            uint256 proposalID = proposalIDs[i];
            UpkeepAction upkeepAction;
            (upkeepNeeded, upkeepAction) = _requiredUpkeep(proposalID);

            if (upkeepNeeded) {
                performData = abi.encodePacked(proposalID, upkeepAction);
                return (upkeepNeeded, performData);
            }
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        (uint256 _proposalID, UpkeepAction upkeepAction) = abi.decode(
            performData,
            (uint256, UpkeepAction)
        );

        if (upkeepAction == UpkeepAction.Tally) {
            tally(_proposalID);
        } else if (upkeepAction == UpkeepAction.Finalize) {
            finalize(_proposalID);
        } else if (upkeepAction == UpkeepAction.Queue) {
            queue(_proposalID);
        } else if (upkeepAction == UpkeepAction.Execute) {
            execute(_proposalID);
        }
    }

    function _requiredUpkeep(
        uint256 _proposalID
    ) internal view returns (bool, UpkeepAction) {
        ProposalState proposalState = state(_proposalID);
        Proposal memory proposal = proposals[_proposalID];
        bytes32 requestID = proposal.requestID;

        IDKG.TallyTrackerState trackerState = dkg.getTallyTrackerState(
            requestID
        );
        IDKG.TallyTracker memory tracker = dkg.getTallyTracker(requestID);

        if (
            proposalState == ProposalState.Tallying &&
            (tracker.dao == address(0))
        ) {
            return (true, UpkeepAction.Tally);
        } else if (
            proposalState == ProposalState.Tallying &&
            trackerState == IDKG.TallyTrackerState.RESULT_SUBMITTED
        ) {
            return (true, UpkeepAction.Finalize);
        } else if (proposalState == ProposalState.Succeeded) {
            return (true, UpkeepAction.Queue);
        } else if (
            proposalState == ProposalState.Queued &&
            block.number >= proposal.eta
        ) {
            return (true, UpkeepAction.Execute);
        }
    }
}
