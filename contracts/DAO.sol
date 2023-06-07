pragma solidity ^0.8.0;

import "./interfaces/IDAO.sol";
import "./interfaces/IDKG.sol";
import "./interfaces/IDKGRequest.sol";
import "./interfaces/ITimelock.sol";
import "./libs/Math.sol";
import "./libs/MerkleTree.sol";
import "./FundManager.sol";

contract DAO is IDAO, IDKGRequest {
    uint256 internal constant Q =
        0x30644E72E131A029B85045B68181585D2833E84879B9709143E1F593F0000001;
    // Used to read proposals data
    uint256 internal constant PROPOSAL_STORAGE_SIZE = 6;

    // Number
    uint256 internal constant VOTE_OPTIONS = 3;

    // Configuration for governor processes.
    Config public config;

    //
    FundManager public fundManager;

    // The address of the DKG contract.
    IDKG public dkg;

    // Number of proposal created
    uint256 private proposalCount;

    // Public key for vote encryption
    uint256 private distributedKeyId;

    // Index of proposals' ID.
    mapping(uint256 => uint256) public proposalIds;

    // Record of all proposals ever proposed.
    mapping(uint256 => Proposal) public proposals;

    // Record of DKG request of proposals
    mapping(bytes32 => Request) public requests;

    // Record of nullifier hashes of proposals for preventing double-voting
    mapping(uint256 => mapping(uint256 => bool)) public nullifierHashes;

    // Queue for timelock
    mapping(bytes32 => bool) public queuedTransactions;

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

    modifier onlyFundManager() {
        require(
            msg.sender == address(fundManager),
            "DAO::onlyFundManager: call must come from the FundManager contract"
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
        uint256 _distributedKeyId
    ) {
        config = _config;
        fundManager = FundManager(_fundManager);
        dkg = IDKG(_dkg);
        distributedKeyId = _distributedKeyId;
    }

    /**
     * =========================
     * ===== DAO FUNCTIONs =====
     * =========================
     */

    /**
     * Propose a new proposal with special requirements for proposer.
     * @param actions Proposal's actions
     * @param descriptionHash IPFS hash of proposal's description
     * @return Proposal's index
     */
    function propose(Action[] calldata actions, bytes32 descriptionHash) external override returns (uint256) {
        
        uint256 proposalId = hashProposal(actions, descriptionHash);
        proposalIds[proposalCount] = proposalId;
        Proposal storage newProposal = proposals[proposalId];
        
        // Check new proposal has  not exist
        require(
            newProposal.startBlock == 0,
            "DAO::propose: proposal already existed"
        );
        
        // Check vote encryption key is usable and dkg type is correct
        require(
            dkg.getDistributedKeyState(distributedKeyId) == IDKG.DistributedKeyState.ACTIVE &&
            dkg.getType(distributedKeyId) == IDKG.DistributedKeyType.VOTING
        );
        
        // Check vote encryption key's verifier has the correct dimenstion
        uint8 dimension = dkg.getDimension(distributedKeyId);
        require(dimension == VOTE_OPTIONS, "DAO::propose: can not use distributed key with the wrong dimension");
                
        // Assign proposal's data
        uint64 startBlock = uint64(block.number + config.pendingPeriod);

        newProposal.id = hashProposal(actions, descriptionHash);
        newProposal.startBlock = startBlock;

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
            actions,
            startBlock,
            descriptionHash
        );

        // Increase proposal counter
        ++proposalCount;

        return proposalCount;
    }

    function castVote(
        uint256 proposalId,
        VoteData calldata voteData
    ) external override {
        Proposal memory proposal = proposals[proposalId];

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
    function tally(uint256 proposalId) external override {
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
    function finalize(uint256 proposalId) external override {
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
     * @param actions Proposal's actions
     * @param descriptionHash IPFS hash of proposal's description
     */
    function queue(Action[] calldata actions, bytes32 descriptionHash) external override {
        uint256 proposalId = hashProposal(actions, descriptionHash);
        require(
            state(proposalId) == ProposalState.Succeeded,
            "DAO::queue: Proposal has not been finalized yet"
        );

        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.number + config.timelockPeriod;

        for (uint256 i = 0; i < actions.length; i++) {
            _queueTransaction(
                actions[i].target,
                actions[i].value,
                actions[i].signature,
                actions[i].data,
                eta
            );
        }
        proposal.eta = eta;

        emit ProposalQueued(proposalId, eta);
    }

    /**
     * Execute a succeeded proposal. This requires the quorum to be reached, the vote to be successful, and the timelock delay period has passed.
     * @param actions Proposal's actions
     * @param descriptionHash IPFS hash of proposal's description
     */
    function execute(Action[] calldata actions, bytes32 descriptionHash) external payable override {
        uint256 proposalId = hashProposal(actions, descriptionHash);
        require(
            state(proposalId) == ProposalState.Queued,
            "DAO::queue: Proposal has not been queued yet"
        );

        Proposal storage proposal = proposals[proposalId];
        uint256 eta = proposal.eta;

        for (uint256 i = 0; i < actions.length; i++) {
            _executeTransaction(
                actions[i].target,
                actions[i].value,
                actions[i].signature,
                actions[i].data,
                eta
            );
        }
        proposal.executed = true;

        emit ProposalExecuted(proposalId);
    }

    /**
     * Cancel a queued proposal. This requires the proposer has not been executed yet.
     * @param actions Proposal's actions
     * @param descriptionHash IPFS hash of proposal's description
     */
    function cancel(Action[] calldata actions, bytes32 descriptionHash) external override {
        uint256 proposalId = hashProposal(actions, descriptionHash);
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

        // FIXME consider to cancel queued proposals only or not
        for (uint256 i = 0; i < actions.length; i++) {
            _cancelTransaction(
                actions[i].target,
                actions[i].value,
                actions[i].signature,
                actions[i].data,
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
     * @param actions Proposal's actions
     * @param descriptionHash IPFS hash of proposal's description
     */
    function hashProposal(
        Action[] calldata actions,
        bytes32 descriptionHash
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(actions, descriptionHash))) % Q;
    }

    /**
     * Gets the status of a proposal.
     * @param proposalId The id of the proposal
     * @return Proposal's status
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal memory proposal = proposals[proposalId];
        Config memory daoConfig = config;
        Request memory request = requests[getProposalRequestId((proposalId))];
        require(
            proposal.startBlock > 0,
            "DAO::state: proposal not existed."
        );
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (
            block.number <= (proposal.startBlock + daoConfig.votingPeriod)
        ) {
            return ProposalState.Active;
        } else if (
            block.number <=
            (proposal.startBlock +
                daoConfig.votingPeriod +
                daoConfig.tallyingPeriod)
        ) {
            return ProposalState.Tallying;
        } else if (
            proposal.forVotes + proposal.againstVotes + proposal.abstainVotes == 0 ||
            request.respondedAt > (proposal.startBlock + daoConfig.votingPeriod + daoConfig.tallyingPeriod)
        ) {
            return ProposalState.Expired;
        } else if (proposal.forVotes <= proposal.againstVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (
            block.number >= (proposal.eta + daoConfig.queuingPeriod)
        ) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function getProposalRequestId(uint256 proposalId) public view returns (bytes32 requestId) {
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
    ) external view override returns (uint256) {}

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
        string calldata _signature,
        bytes calldata _data, 
        uint256 _eta
    ) internal returns (bytes32) {
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

        // emit TransactionQueued(
        //     txHash,
        //     _target,
        //     _value,
        //     _signature,
        //     _data,
        //     _eta
        // );
        return txHash;
    }

    function _cancelTransaction(
        address _target,
        uint _value,
        string calldata _signature,
        bytes calldata _data, 
        uint256 _eta
    ) internal {
        bytes32 txHash = keccak256(
            abi.encode(_target, _value, _signature, _data, _eta)
        );

        queuedTransactions[txHash] = false;

        // emit TransactionCancelled(
        //     txHash,
        //     _target,
        //     _value,
        //     _signature,
        //     _data,
        //     _eta
        // );
    }

    function _executeTransaction(
        address _target,
        uint _value,
        string calldata _signature,
        bytes calldata _data, 
        uint256 _eta
    ) internal returns (bytes memory) {
        bytes32 txHash = keccak256(
            abi.encode(_target, _value, _signature, _data, _eta)
        );
        require(
            queuedTransactions[txHash],
            "DAO::_executeTransaction: Transaction hasn't been queued."
        );
        require(
            block.number >= _eta,
            "DAO::_executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            block.number <= (_eta + config.queuingPeriod),
            "DAO::_executeTransaction: Transaction is expired."
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

        // emit TransactionExecuted(
        //     txHash,
        //     _target,
        //     _value,
        //     _signature,
        //     _data,
        //     _eta
        // );

        return returnData;
    }

    receive() external payable {}
}
