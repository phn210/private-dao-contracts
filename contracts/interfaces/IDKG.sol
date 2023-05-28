// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVerifier.sol";

interface IDKG {
    enum DistributedKeyType {
        FUNDING,
        VOTING
    }

    /**
     * ROUND_1_CONTRIBUTION => CONTRIBUTION_ROUND_1
     * ROUND_2_CONTRIBUTION => CONTRIBUTION_ROUND_2
     * MAIN => ACTIVE
     * FAILED => DISABLED
     */

    enum DistributedKeyState {
        ROUND_1_CONTRIBUTION,
        ROUND_2_CONTRIBUTION,
        MAIN,
        FAILED
    }

    /**
     * TallyTrackerState => RequestState
     * TALLY_CONTRIBUTION => CONTRIBUTION
     * TALLY_RESULT_CONTRIBUTION => WAITING
     * END => FINALIZED
     */
    enum TallyTrackerState {
        TALLY_CONTRIBUTION,
        TALLY_RESULT_CONTRIBUTION,
        END
    }

    struct DKGConfig {
        uint256 round1Period;
        uint256 round2Period;
        address round2Verfier;
        address fundingVerifier;
        address votingVerifier;
        address tallyContributionVerfier;
        address tallyResultContributionVerifier;
        address resultVerifier;
    }

    /**
     * Consider to remove
     * state: use multiple if else => a function
     *   round 1 contribution < n => CONTRIBUTION_ROUND_1
     *   round 2 contribution < n => CONTRIBUTION_ROUND_2
     *   flag disabled true => DISABLED
     *   => ACTIVE
     * round1Counter: check contribution array
     * round2Counter: same and use 2 dimension array
     * startTimestamps: why necessary?
     * usageCOunter: why necessary? if it's only for one-time key => bool
     */
    struct DistributedKey {
        DistributedKeyType keyType;
        DistributedKeyState state;
        uint8 dimension;
        uint8 round1Counter;
        uint8 round2Counter;
        address verifier;
        uint256 publicKeyX;
        uint256 publicKeyY;
        Round1Contribution[] round1Contributions;
        mapping(uint8 => Round2Contribution[]) round2Contributions;
        uint256 startRound1Timestamp;
        uint256 startRound2Timestamp;
        uint256 usageCounter;
    }

    struct Round1Contribution {
        address sender;
        uint8 senderIndex;
        uint256[] x;
        uint256[] y;
    }

    struct Round2Contribution {
        uint8 senderIndex;
        uint256[] cipher;
    }

    /**
     * TallyTracker => an extended version of IDKGRequest.Request :v
     * => IDKG.Request & IDKGRequest.RequestInfo
     * Consider to remove/replace
     * state: use multiple if else => a function
     *   contribution < t => CONTRIBUTION
     *   result.length = 0 => WAITING   
     *   finalized flag => FINALIZED
     * tallyCounter: check tallyContributions.length
     * dao => requestor
     * verifiers => only necessary if verifier contract address can be changed
     * => can be replaced by global mapping for code simplicity & gas optimization
     */
    struct TallyTracker {
        uint256 distributedKeyID;
        uint256[][] R;
        uint256[][] M;
        TallyTrackerState state;
        TallyContribution[] tallyContributions;
        address dao;
        address tallyContributionVerifier;
        address tallyResultContributionVerifier;
        address resultVerifier;
        uint8 tallyCounter;
        uint256[] tallyResult;
    }

    struct TallyContribution {
        uint8 i;
        uint256[][] Di;
    }

    /*====================== MODIFIER ======================*/

    modifier onlyOwner() virtual;

    modifier onlyCommittee() virtual;

    modifier onlyWhitelistedDAO() virtual;

    /*================== EXTERNAL FUNCTION ==================*/

    function generateDistributedKey(
        uint8 _dimension,
        DistributedKeyType _distributedKeyType
    ) external returns (uint256 distributedKeyID);

    function submitRound1Contribution(
        uint256 _distributedKeyID,
        uint256[] calldata _x,
        uint256[] calldata _y
    ) external returns (uint8);

    function submitRound2Contribution(
        uint256 _distributedKeyID,
        uint8[] calldata _committeeIndexes,
        uint256[][] calldata _ciphers,
        bytes[] calldata _proofs
    ) external;

    function startTallying(
        bytes32 _requestID,
        uint256 _distributedKeyID,
        uint256[][] memory _R,
        uint256[][] memory _M
    ) external;

    function submitTallyContribution(
        bytes32 _requestID,
        uint8 _senderIndex,
        uint256[][] calldata _Di,
        bytes calldata _proof
    ) external;

    function submitTallyingResult(
        bytes32 _requestID,
        uint256[] calldata _result,
        bytes calldata _proof
    ) external;

    /*==================== VIEW FUNCTION ====================*/

    function getUsageCounter(
        uint256 _distributedKeyID
    ) external view returns (uint256);

    function getDimension(
        uint256 _distributedKeyID
    ) external view returns (uint8);

    function getState(
        uint256 _distributedKeyID
    ) external view returns (DistributedKeyState);

    function getType(
        uint256 _distributedKeyID
    ) external view returns (DistributedKeyType);

    function getRound1Contribution(
        uint256 _distributedKeyID,
        uint8 _senderIndex
    ) external view returns (Round1Contribution memory);

    function getPublicKey(
        uint256 _distributedKeyID
    ) external view returns (uint256, uint256);

    function getVerifier(
        uint256 _distributedKeyID
    ) external view returns (IVerifier);

    function getTallyResultVector(
        bytes32 _requestID
    ) external view returns (uint256[][] memory);
}
