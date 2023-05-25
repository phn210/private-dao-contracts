// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVerifier.sol";

interface IDKG {
    enum DistributedKeyType {
        FUNDING,
        VOTING
    }

    enum DistributedKeyState {
        ROUND_1_CONTRIBUTION,
        ROUND_2_CONTRIBUTION,
        MAIN,
        FAILED
    }

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
    }

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

    function startTally(
        bytes32 _proposalID,
        uint256 _distributedKeyID,
        uint256[][] memory _R,
        uint256[][] memory _M
    ) external;

    function submitTallyContribution(
        bytes32 _proposalID,
        uint8 _senderIndex,
        uint256[][] calldata _Di,
        bytes calldata _proof
    ) external;

    function submitTallyResult(
        bytes32 _proposalID,
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

    function getRound1Contribution(
        uint256 _distributedKeyID,
        uint8 _senderIndex
    ) external view returns (Round1Contribution memory);

    function getPublicKey(
        uint256 _distributedKeyID
    ) external view returns (uint256, uint256);

    function getVerifier(
        uint256 _distributedKeyID
    ) external view returns (address);

    function getTallyResultVector(
        bytes32 _proposalID
    ) external view returns (uint256[][] memory);
}
