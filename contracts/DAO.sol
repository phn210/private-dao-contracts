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
    Config private config;

    //
    FundManager private fundManager;

    // The address of the DKG contract.
    IDKG private dkg;

    // Number of proposal created
    uint256 public proposalCount;

    // Public key for vote encryption
    uint256 private distributedKeyId;

    // Index of proposals' ID.
    mapping(uint256 => uint256) public proposalIds;

    // Record of all proposals ever proposed.
    mapping(uint256 => Proposal) public proposals;

    // Record of DKG request of proposals
    mapping(bytes32 => Request) public requests;

    mapping(uint256 => Action[]) private actions;

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
        uint256 _distributedKeyId,
        bytes32 _descriptionHash
    ) {
        config = _config;
        fundManager = FundManager(_fundManager);
        dkg = IDKG(_dkg);
        distributedKeyId = _distributedKeyId;
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
        uint256 proposalId = hashProposal(_actions, _descriptionHash);
        proposalIds[proposalCount] = proposalId;
        Proposal storage newProposal = proposals[proposalId];

        // Check new proposal has  not exist
        require(
            newProposal.startBlock == 0,
            "DAO::propose: proposal already existed"
        );

        // Check vote encryption key is usable and dkg type is correct
        require(
            dkg.getDistributedKeyState(distributedKeyId) ==
                IDKG.DistributedKeyState.ACTIVE &&
                dkg.getType(distributedKeyId) == IDKG.DistributedKeyType.VOTING
        );

        // Check vote encryption key's verifier has the correct dimenstion
        uint8 dimension = dkg.getDimension(distributedKeyId);
        require(
            dimension == VOTE_OPTIONS,
            "DAO::propose: can not use distributed key with the wrong dimension"
        );

        // Assign proposal's data
        uint64 startBlock = uint64(block.number + config.pendingPeriod);

        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.startBlock = startBlock;

        Action[] storage proposalActions = actions[proposalId];
        // proposalActions.push(_actions);
        descriptions[proposalId] = _descriptionHash;

        bytes32 requestId = getRequestID(
            distributedKeyId,
            address(this),
            proposalId
        );

        // Assign dkg request data for this proposal
        Request storage request = requests[requestId];
        request.distributedKeyID = distributedKeyId;
        for (uint8 i; i < dimension; i++) {
            request.R.push([0, 1]);
            request.M.push([0, 1]);
        }

        emit ProposalCreated(
            proposalCount,
            proposalId,
            msg.sender,
            _actions,
            startBlock,
            _descriptionHash
        );

        // Increase proposal counter
        ++proposalCount;

        return proposalCount;
    }

    function castVote(
        uint256 proposalId,
        VoteData calldata voteData
    ) external override {
        Proposal storage proposal = proposals[proposalId];

        require(
            state(proposalId) == ProposalState.Active,
            "DAO::CastVote: Proposal is not in the voting period"
        );

        require(
            !nullifierHashes[proposalId][voteData.nullifierHash],
            "DAO::CastVote: Double voting is not allowed"
        );

        require(
            fundManager.isKnownRoot(voteData.root),
            "DAO::CastVote: Root is invalid"
        );

        nullifierHashes[proposalId][voteData.nullifierHash] = true;

        bytes32 requestId = getRequestID(
            distributedKeyId,
            address(this),
            proposalId
        );
        Request storage request = requests[requestId];

        uint8 dimension = dkg.getDimension(request.distributedKeyID);
        require(
            voteData._R.length == dimension && voteData._M.length == dimension,
            "FundManager: invalid input length"
        );

        IVerifier verifier = dkg.getVerifier(request.distributedKeyID);
        uint256[] memory publicInputs = new uint256[](
            verifier.getPublicInputsLength()
        );

        publicInputs[0] = voteData.root;
        publicInputs[1] = (uint256)(uint160(address(this)));
        publicInputs[2] = proposalId;
        (publicInputs[3], publicInputs[4]) = dkg.getPublicKey(
            request.distributedKeyID
        );
        publicInputs[5] = voteData.nullifierHash;
        for (uint8 i; i < dimension; i++) {
            publicInputs[6 + 2 * i] = voteData._R[i][0];
            publicInputs[6 + 2 * i + 1] = voteData._R[i][1];
            publicInputs[6 + 2 * dimension + 2 * i] = voteData._M[i][0];
            publicInputs[6 + 2 * dimension + 2 * i + 1] = voteData._M[i][1];
        }

        require(
            _verifyProof(verifier, voteData._proof, publicInputs),
            "DAO::CastVote: ZK Proof is invalid"
        );

        for (uint8 i; i < dimension; i++) {
            (request.R[i][0], request.R[i][1]) = CurveBabyJubJub.pointAdd(
                request.R[i][0],
                request.R[i][1],
                voteData._R[i][0],
                voteData._R[i][1]
            );
            (request.M[i][0], request.M[i][1]) = CurveBabyJubJub.pointAdd(
                request.M[i][0],
                request.M[i][1],
                voteData._M[i][0],
                voteData._M[i][1]
            );
        }

        emit VoteCast(proposalId, voteData.nullifierHash);
    }

    /**
     * Tally the result of a proposal.
     * @param proposalId The id of the proposal to tally
     */
    function tally(uint256 proposalId) public override {
        require(
            state(proposalId) == ProposalState.Tallying,
            "DAO::tally: not in the tallying period"
        );

        bytes32 requestId = getProposalRequestId(proposalId);
        Request storage request = requests[requestId];

        dkg.startTallying(
            requestId,
            request.distributedKeyID,
            request.R,
            request.M
        );

        emit ProposalTallyingStarted(proposalId, requestId);
    }

    function submitTallyResult(
        bytes32 _requestID,
        uint256[] calldata _result
    ) external override onlyDKG {
        Request storage request = requests[_requestID];
        require(
            request.distributedKeyID == distributedKeyId,
            "DAO::submitTallyingResult: request does not exist"
        );
        request.result = _result;
        request.respondedAt = block.number;
    }

    /**
     * Finalize the result of a proposal.
     * @param proposalId The id of the proposal to finalize
     */
    function finalize(uint256 proposalId) public override {
        require(
            state(proposalId) == ProposalState.Tallying,
            "DAO::finalize: not in the tallying period"
        );

        bytes32 requestId = getProposalRequestId(proposalId);
        Request storage request = requests[requestId];

        require(
            request.respondedAt > 0,
            "DAO::finalize: DKG request has not been responded"
        );

        Proposal storage proposal = proposals[proposalId];

        uint256 forVotes = request.result[uint256(VoteOption.For)];
        uint256 againstVotes = request.result[uint256(VoteOption.Against)];
        uint256 abstainVotes = request.result[uint256(VoteOption.Abstain)];

        proposal.forVotes = forVotes;
        proposal.againstVotes = againstVotes;
        proposal.abstainVotes = abstainVotes;

        emit ProposalFinalized(
            proposalId,
            forVotes,
            againstVotes,
            abstainVotes
        );
    }

    /**
     * Queue a succeeded proposal. This requires the quorum to be reached, the vote to be successful, and the voting period has ended.
     * @param proposalId The id of the proposal to queue
     */
    function queue(uint256 proposalId) public override {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "DAO::queue: Proposal has not been finalized yet"
        );

        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.number + config.timelockPeriod;

        Action[] storage proposalActions = actions[proposalId];

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

        emit ProposalQueued(proposalId, eta);
    }

    /**
     * Execute a succeeded proposal. This requires the quorum to be reached, the vote to be successful, and the timelock delay period has passed.
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint256 proposalId) public payable override {
        require(
            state(proposalId) == ProposalState.Queued,
            "DAO::queue: Proposal has not been queued yet"
        );

        Proposal storage proposal = proposals[proposalId];
        uint256 eta = proposal.eta;

        Action[] storage proposalActions = actions[proposalId];

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

        emit ProposalExecuted(proposalId);
    }

    /**
     * Cancel a queued proposal. This requires the proposer has not been executed yet.
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(uint256 proposalId) public override {
        require(
            state(proposalId) != ProposalState.Executed,
            "DAO::cancel: Cannot cancel executed proposal"
        );
        require(
            state(proposalId) != ProposalState.Canceled,
            "DAO::cancel: Cannot cancel canceled proposal"
        );

        Proposal storage proposal = proposals[proposalId];

        proposal.canceled = true;

        Action[] storage proposalActions = actions[proposalId];

        for (uint256 i = 0; i < proposalActions.length; i++) {
            _cancelTransaction(
                proposalActions[i].target,
                proposalActions[i].value,
                proposalActions[i].signature,
                proposalActions[i].data,
                proposal.eta
            );
        }

        emit ProposalCanceled(proposalId);
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
     * @param proposalId The id of the proposal
     * @return Proposal's status
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal memory proposal = proposals[proposalId];
        Request memory request = requests[getProposalRequestId((proposalId))];
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

    function getProposalRequestId(
        uint256 proposalId
    ) public view returns (bytes32 requestId) {
        requestId = getRequestID(distributedKeyId, address(this), proposalId);
    }

    /**
     * =================================
     * ===== DKG REQUEST FUNCTIONS =====
     * =================================
     */

    function getRequestID(
        uint256 _distributedKeyId,
        address _requestor,
        uint256 _nonce
    ) public pure override returns (bytes32) {
        return
            keccak256(abi.encodePacked(_distributedKeyId, _requestor, _nonce));
    }

    function getDistributedKeyID(
        bytes32 _requestID
    ) external view override returns (uint256) {
        return requests[_requestID].distributedKeyID;
    }

    function getRequestResult(
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
            rangeToCheck[1] >= proposalCount ||
            rangeToCheck[0] > rangeToCheck[1] ||
            rangeToCheck[0] >= proposalCount
        ) revert("DAO::checkUpkeep: Invalid range!");

        for (uint256 i = rangeToCheck[0]; i <= rangeToCheck[1]; i++) {
            if (i >= proposalCount) continue;
            uint256 proposalId = proposalIds[i];
            UpkeepAction upkeepAction;
            (upkeepNeeded, upkeepAction) = _requiredUpkeep(proposalId);

            if (upkeepNeeded) {
                performData = abi.encodePacked(proposalId, upkeepAction);
                return (upkeepNeeded, performData);
            }
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        (uint256 proposalId, UpkeepAction upkeepAction) = abi.decode(
            performData,
            (uint256, UpkeepAction)
        );

        if (upkeepAction == UpkeepAction.Tally) {
            tally(proposalId);
        } else if (upkeepAction == UpkeepAction.Finalize) {
            finalize(proposalId);
        } else if (upkeepAction == UpkeepAction.Queue) {
            queue(proposalId);
        } else if (upkeepAction == UpkeepAction.Execute) {
            execute(proposalId);
        }
    }

    function _requiredUpkeep(
        uint256 proposalId
    ) internal view returns (bool, UpkeepAction) {
        ProposalState proposalState = state(proposalId);
        bytes32 requestId = getProposalRequestId(proposalId);

        Proposal memory proposal = proposals[proposalId];
        IDKG.TallyTrackerState trackerState = dkg.getTallyTrackerState(
            requestId
        );
        IDKG.TallyTracker memory tracker = dkg.getTallyTracker(requestId);

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
