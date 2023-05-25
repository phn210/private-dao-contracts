// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        bytes32 proposalID;
        address[] listDAO;
        uint256[] listCommitment;
        mapping(address => uint256) balances;
        mapping(address => uint256) daoBalances;
        FundingRoundState state;
        uint256 pendingStartBN;
        uint256 activeStartBN;
        uint256 tallyStartBN;
        uint256 succeededBN;
        uint256 finalizedBN;
        uint256 failedBN;
    }

    struct FundingRoundConfig {
        uint256 fundingRoundInterval;
        uint256 pendingPeriodBN;
        uint256 activePeriodBN;
        uint256 tallyingPeriodBN;
    }

    struct MerkleTreeConfig {
        uint32 levels;
        address poseidon;
    }

    /*====================== MODIFIER ======================*/

    modifier onlyFounder() virtual;

    modifier onlyCommittee() virtual;

    modifier onlyWhitelistedDAO() virtual;

    /*================== EXTERNAL FUNCTION ==================*/

    function applyForFunding() external;

    function launchFundingRound(
        uint256 _distributedKeyID
    ) external returns (bytes32);

    function fund(
        bytes32 _proposalID,
        uint256 _commitment,
        uint256[][] calldata _R,
        uint256[][] calldata _M,
        bytes calldata _proof
    ) external payable;

    function startTallying(bytes32 _proposalID) external;

    function finalizeFundingRound(bytes32 _proposalID) external;

    function refund(bytes32 _proposalID) external;

    function withdrawFund(bytes32 _proposalID, address _dao) external;

    /*==================== VIEW FUNCTION ====================*/

    function isCommittee(address _sender) external view returns (bool);

    function isWhitelistedDAO(address _sender) external view returns (bool);

    function getDKGParams() external view returns (uint8, uint8);
}
