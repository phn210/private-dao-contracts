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
        uint256 pendingStartTimestamp;
        uint256 activeStartTimestamp;
        uint256 tallyStartTimestamp;
        uint256 succeededTimestamp;
        uint256 finalizedTimestamp;
        uint256 failedTimestamp;
    }

    struct FundingRoundConfig {
        uint256 fundingRoundInterval;
        uint256 fundingRoundPeriod;
        uint256 pendingPeriod;
        uint256 activePeriod;
        uint256 tallyingPeriod;
    }

    /*====================== MODIFIER ======================*/

    /*================== EXTERNAL FUNCTION ==================*/

    function applyForFunding() external;

    function launchFundingRound() external;

    function startTallying() external;

    function submitTallyingResult() external;

    function finalizeFundingRound() external;

    /*==================== VIEW FUNCTION ====================*/

    function isCommittee(address _sender) external view returns (bool);

    function isWhitelistedDAO(address _sender) external view returns (bool);

    function getDKGParams() external view returns (uint8, uint8);
}
