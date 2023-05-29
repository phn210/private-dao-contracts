// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVerifier.sol";

interface IDKG {
    enum DistributedKeyType {
        FUNDING,
        VOTING
    }

    /**
     * CONTRIBUTION_ROUND_1 => CONTRIBUTION_ROUND_1
     * CONTRIBUTION_ROUND_2 => CONTRIBUTION_ROUND_2
     * ACTIVE => ACTIVE
     * DISABLED => DISABLED
     */

    enum DistributedKeyState {
        CONTRIBUTION_ROUND_1,
        CONTRIBUTION_ROUND_2,
        ACTIVE,
        DISABLED
    }

    /**
     * TallyTrackerState => RequestState
     * TALLY_CONTRIBUTION => CONTRIBUTION
     * TALLY_RESULT_CONTRIBUTION => WAITING
     * END => FINALIZED
     */
    enum TallyTrackerState {
        CONTRIBUTION,
        RESULT_AWAITING,
        RESULT_SUBMITTED
    }

    struct DKGConfig {
        address round2Verfier;
        address fundingVerifier;
        address votingVerifier;
        address tallyContributionVerifier;
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
        uint8 dimension;
        uint8 round1Counter;
        uint8 round2Counter;
        address verifier;
        uint256 publicKeyX;
        uint256 publicKeyY;
        Round1DataSubmission[] round1DataSubmissions;
        mapping(uint8 => Round2DataSubmission[]) round2DataSubmissions;
        uint256 usageCounter;
    }

    struct Round1DataSubmission {
        address sender;
        uint8 senderIndex;
        uint256[] x;
        uint256[] y;
    }

    struct Round1Contribution {
        uint256[] x;
        uint256[] y;
    }

    struct Round2DataSubmission {
        uint8 senderIndex;
        uint256[] cipher;
    }

    struct Round2Contribution {
        uint8 senderIndex;
        uint8[] recipientIndexes;
        uint256[][] ciphers;
        bytes[] proofs;
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
        TallyDataSubmission[] tallyDataSubmissions;
        uint8 tallyCounter;
        bool resultSubmitted;
        address dao;
        address contributionVerifier;
        address resultVerifier;
        uint256[] tallyResult;
    }

    struct TallyDataSubmission {
        uint8 senderIndex;
        uint256[][] Di;
    }
    struct TallyContribution {
        uint8 senderIndex;
        uint256[][] Di;
        bytes proof;
    }

    /*====================== MODIFIER ======================*/

    modifier onlyFounder() virtual;

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
        Round1Contribution calldata _round1Contribution
    ) external returns (uint8);

    function submitRound2Contribution(
        uint256 _distributedKeyID,
        Round2Contribution calldata _round2Contribution
    ) external;

    function startTallying(
        bytes32 _requestID,
        uint256 _distributedKeyID,
        uint256[][] memory _R,
        uint256[][] memory _M
    ) external;

    function submitTallyContribution(
        bytes32 _requestID,
        TallyContribution calldata _tallyContribution
    ) external;

    function submitTallyResult(
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

    function getDistributedKeyState(
        uint256 _distributedKeyID
    ) external view returns (DistributedKeyState);

    function getType(
        uint256 _distributedKeyID
    ) external view returns (DistributedKeyType);

    function getRound1DataSubmission(
        uint256 _distributedKeyID,
        uint8 _senderIndex
    ) external view returns (Round1DataSubmission memory);

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
