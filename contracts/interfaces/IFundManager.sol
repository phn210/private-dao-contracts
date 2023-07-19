// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDKGRequest.sol";

interface IFundManager {
    enum FundingRoundState {
        PENDING,
        ACTIVE,
        TALLYING,
        SUCCEEDED,
        FINALIZED,
        FAILED
    }

    struct FundingRound {
        bytes32 requestID;
        address[] listDAO;
        uint256[] listCommitment;
        uint256 balance;
        mapping(address => uint256) balances;
        mapping(address => uint256) daoBalances;
        uint64 launchedAt;
        uint64 finalizedAt;
        uint64 failedAt;
    }

    struct FundingRoundConfig {
        uint64 pendingPeriod;
        uint64 activePeriod;
        uint64 tallyPeriod;
    }

    struct MerkleTreeConfig {
        uint32 levels;
        address poseidon;
    }

    /*======================= EVENT =======================*/

    event FundingRoundApplied(address indexed dao);

    event FundingRoundLaunched(
        uint256 indexed fundingRoundID,
        bytes32 indexed requestID
    );

    event Funded(
        uint256 indexed fundingRoundID,
        address sender,
        uint256 value,
        uint256 indexed commitment
    );

    event TallyStarted(
        uint256 indexed fundingRoundID,
        bytes32 indexed requestID
    );

    event TallyResultSubmitted(
        bytes32 indexed requestID,
        uint256[] indexed result
    );

    event FundingRoundFinalized(uint256 indexed fundingRoundID);

    event FundingRoundFailed(uint256 indexed fundingRoundID);

    event Refunded(
        uint256 indexed fundingRoundID,
        address indexed refundee,
        uint256 indexed value
    );

    event FundWithdrawed(
        uint256 indexed fundingRoundID,
        address indexed dao,
        uint256 indexed value
    );
    /*====================== MODIFIER ======================*/

    modifier onlyFounder() virtual;

    modifier onlyCommittee() virtual;

    modifier onlyDAOManager() virtual;

    /*================== EXTERNAL FUNCTION ==================*/

    function applyForFunding(address dao) external;

    function launchFundingRound(
        uint256 _distributedKeyID
    ) external returns (uint256, bytes32);

    function fund(
        uint256 _fundingRoundID,
        uint256 _commitment,
        uint256[][] calldata _R,
        uint256[][] calldata _M,
        bytes calldata _proof
    ) external payable;

    function startTallying(uint256 _fundingRoundID) external;

    function finalizeFundingRound(uint256 _fundingRoundID) external;

    function refund(uint256 _fundingRoundID) external;

    function withdrawFund(uint256 _fundingRoundID, address _dao) external;

    /*==================== VIEW FUNCTION ====================*/

    function getFundingRoundQueueLength() external view returns (uint256);

    function isCommittee(address _sender) external view returns (bool);

    function isFounder(address _sender) external view returns (bool);

    function getDKGParams() external view returns (uint8, uint8);

    function getListDAO(
        uint256 _fundingRoundID
    ) external view returns (address[] memory);

    function getFundingRoundBalance(
        uint256 _fundingRoundID
    ) external view returns (uint256);
}
