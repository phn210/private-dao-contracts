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

    /*====================== MODIFIER ======================*/

    modifier onlyOwner() virtual;

    modifier onlyCommittee() virtual;

    modifier onlyWhitelistedDAO() virtual;

    /*================== EXTERNAL FUNCTION ==================*/

    function generateDistributedKey() external;

    function submitRound1Contribution() external;

    function submitRound2Contribution() external;

    function startTally() external;

    function submitTallyContribution() external;

    function submitTallyResult() external;

    /*==================== VIEW FUNCTION ====================*/
}
