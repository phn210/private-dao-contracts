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
        mapping(address => uint256) balances;
        mapping(address => uint256) daoBalances;
        uint256 launchedAt;
        uint256 finalizedAt;
    }

    struct FundingRoundConfig {
        uint256 fundingRoundInterval;
        uint256 pendingPeriod;
        uint256 activePeriod;
        uint256 tallyPeriod;
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

    function isCommittee(address _sender) external view returns (bool);

    function isWhitelistedDAO(address _sender) external view returns (bool);

    function isFounder(address _sender) external view returns (bool);

    function getDKGParams() external view returns (uint8, uint8);
}
