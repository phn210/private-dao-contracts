pragma solidity ^0.8.0;

import "./interfaces/IDAO.sol";
import "./interfaces/IDKG.sol";
import "./interfaces/IDKGRequest.sol";
import "./interfaces/IFundManager.sol";
import "./interfaces/ITimelock.sol";

contract DAO is IDAO, IDKGRequest {
    // Used to read proposals data
    uint256 internal constant PROPOSAL_STORAGE_SIZE = 6;

    // Number
    uint256 internal constant VOTE_OPTIONS = 3;

    // Configuration for governor processes.
    Config public config;

    //
    IFundManager public fundManager;

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
    mapping(uint256 => mapping(uint256 => bool)) nullifierHashes;

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
        fundManager = IFundManager(_fundManager);
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
    function propose(
        Action[] calldata actions,
        bytes32 descriptionHash
    ) external override returns (uint256) {
        require(
            dkg.getState(distributedKeyId) == IDKG.DistributedKeyState.ACTIVE &&
                dkg.getType(distributedKeyId) == IDKG.DistributedKeyType.VOTING
        );

        uint8 dimension = dkg.getDimension(distributedKeyId);
        require(
            dimension == VOTE_OPTIONS,
            "DAO::propose: can not use distributed key with the wrong dimension"
        );

        uint256 proposalId = hashProposal(actions, descriptionHash);
        Proposal storage newProposal = proposals[proposalId];
        require(
            newProposal.startBlock == 0,
            "DAO::propose: proposal already existed"
        );

        uint64 startBlock = uint64(block.number + config.pendingPeriod);

        newProposal.id = hashProposal(actions, descriptionHash);
        newProposal.startBlock = startBlock;

        bytes32 requestId = getRequestID(
            distributedKeyId,
            address(this),
            proposalId
        );

        Request storage request = requests[requestId];
        request.distributedKeyID = distributedKeyId;
        for (uint8 i; i < dimension; i++) {
            request.R[i][0] = 0;
            request.R[i][1] = 0;
            request.M[i][0] = 0;
            request.M[i][1] = 0;
        }

        emit ProposalCreated(
            proposalCount,
            proposalId,
            msg.sender,
            actions,
            startBlock,
            descriptionHash
        );

        ++proposalCount;
        return proposalCount;
    }

    function castVote(
        uint256 proposalId,
        uint256 commitment,
        uint256[][] calldata _R,
        uint256[][] calldata _M,
        bytes calldata _proof
    ) external override {}

    /**
     * Tally the result of a proposal.
     * @param proposalId The id of the proposal to tally
     */
    function tally(uint256 proposalId) external override {}

    /**
     * Queue a succeeded proposal. This requires the quorum to be reached, the vote to be successful, and the voting period has ended.
     * @param actions Proposal's actions
     * @param descriptionHash IPFS hash of proposal's description
     */
    function queue(
        Action[] calldata actions,
        bytes32 descriptionHash
    ) external override {}

    /**
     * Execute a succeeded proposal. This requires the quorum to be reached, the vote to be successful, and the timelock delay period has passed.
     * @param actions Proposal's actions
     * @param descriptionHash IPFS hash of proposal's description
     */
    function execute(
        Action[] calldata actions,
        bytes32 descriptionHash
    ) external override {}

    /**
     * Cancel a queued proposal. This requires the proposer has not been executed yet.
     * @param actions Proposal's actions
     * @param descriptionHash IPFS hash of proposal's description
     */
    function cancel(
        Action[] calldata actions,
        bytes32 descriptionHash
    ) external override {}

    function submitTallyResult(
        bytes32 _requestID,
        uint256[] calldata _result
    ) external override {}

    /**
     * Finalize the result of a proposal.
     * @param proposalId The id of the proposal to finalize
     */
    function finalize(uint256 proposalId) external override {}

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
        return uint256(keccak256(abi.encode(actions, descriptionHash)));
    }

    /**
     * Gets the status of a proposal.
     * @param proposalId The id of the proposal
     * @return Proposal's status
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal memory proposal = proposals[proposalId];
        Config memory daoConfig = config;
        require(proposal.startBlock > 0, "DAO::state: proposal not existed.");
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
            proposal.forVotes + proposal.againstVotes + proposal.abstainVotes ==
            0
        ) {
            return ProposalState.Expired;
        } else if (proposal.forVotes <= proposal.againstVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (
            block.timestamp >= (proposal.eta + daoConfig.queuingPeriod)
        ) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * =================================
     * ===== DKG REQUEST FUNCTIONs =====
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

    function getRequest(
        bytes32 _requestID
    ) external view override returns (Request memory) {}

    function getDistributedKeyID(
        bytes32 _requestID
    ) external view override returns (uint256) {}

    function getR(
        bytes32 _requestID
    ) external view override returns (uint256[][] memory) {}

    function getM(
        bytes32 _requestID
    ) external view override returns (uint256[][] memory) {}
}
