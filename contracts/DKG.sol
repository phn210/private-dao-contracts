// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";
import "./interfaces/IDKG.sol";
import "./interfaces/IVerifier.sol";
import "./interfaces/IFundManager.sol";
import "./interfaces/IDKGRequest.sol";
import "./libs/CurveBabyJubJub.sol";
import "./libs/CurveBabyJubJubHelper.sol";
import "./libs/Math.sol";

contract DKG is IDKG {
    address public owner;
    uint256 public distributedKeyCounter;

    mapping(uint256 => DistributedKey) public distributedKeys;
    mapping(bytes32 => TallyTracker) public tallyTrackers;

    IVerifier public round2Verifier;
    // dimension => Verifier
    mapping(uint256 => IVerifier) public fundingVerifiers;
    mapping(uint256 => IVerifier) public votingVerifiers;
    mapping(uint256 => IVerifier) public tallyContributionVerifiers;
    mapping(uint256 => IVerifier) public resultVerifiers;

    mapping(bytes32 => mapping(uint256 => IVerifier)) verifiers;

    constructor(DKGConfig memory _dkgConfig) {
        owner = msg.sender;
        round2Verifier = IVerifier(_dkgConfig.round2Verfier);
        fundingVerifiers[3] = IVerifier(_dkgConfig.fundingVerifier);
        votingVerifiers[3] = IVerifier(_dkgConfig.votingVerifier);
        tallyContributionVerifiers[3] = IVerifier(
            _dkgConfig.tallyContributionVerifier
        );
        resultVerifiers[3] = IVerifier(_dkgConfig.resultVerifier);
    }

    modifier onlyFounder() override {
        require(
            IFundManager(owner).isFounder(msg.sender),
            "dkgContract: msg.sender is not Founder"
        );
        _;
    }

    modifier onlyCommittee() override {
        require(
            IFundManager(owner).isCommittee(msg.sender),
            "dkgContract: msg.sender is not Committee"
        );
        _;
    }

    // modifier onlyWhitelistedDAO() override {
    //     require(
    //         IFundManager(owner).isWhitelistedDAO(msg.sender),
    //         "dkgContract: msg.sender is not whitelisted DAO"
    //     );
    //     _;
    // }

    function generateDistributedKey(
        uint8 _dimension,
        DistributedKeyType _distributedKeyType
    ) external override onlyFounder returns (uint256 distributedKeyID) {
        distributedKeyID = distributedKeyCounter;
        distributedKeyCounter += 1;
        DistributedKey storage distributedKey = distributedKeys[
            distributedKeyID
        ];
        address verifier;
        if (_distributedKeyType == DistributedKeyType.FUNDING) {
            require(
                address(fundingVerifiers[_dimension]) != address(0),
                "DKG Contract: No funding verifier exists with corresponding dimensionality"
            );
            verifier = address(fundingVerifiers[_dimension]);
        } else if (_distributedKeyType == DistributedKeyType.VOTING) {
            require(
                address(votingVerifiers[_dimension]) != address(0),
                "DKG Contract: No voting verifier exists with corresponding dimensionality"
            );
            verifier = address(votingVerifiers[_dimension]);
        }
        distributedKey.keyType = _distributedKeyType;
        distributedKey.dimension = _dimension;
        distributedKey.verifier = verifier;
        distributedKey.publicKeyX = 0;
        distributedKey.publicKeyY = 1;
        distributedKey.usageCounter = 0;

        emit DistributedKeyGenerated(distributedKeyID);
    }

    function submitRound1Contribution(
        uint256 _distributedKeyID,
        Round1Contribution calldata _round1Contribution
    ) external override onlyCommittee returns (uint8) {
        DistributedKey storage distributedKey = distributedKeys[
            _distributedKeyID
        ];
        (uint8 t, ) = IFundManager(owner).getDKGParams();
        require(_distributedKeyID < distributedKeyCounter, "dkgContract: invalid distributedKeyID");
        require(
            getDistributedKeyState(_distributedKeyID) ==
                DistributedKeyState.CONTRIBUTION_ROUND_1,
            "dkgContract: key's state is not CONTRIBUTION_ROUND_1"
        );
        require(
            _round1Contribution.x.length == _round1Contribution.y.length &&
                _round1Contribution.x.length == t,
            "dkgContract: invalid input length"
        );

        for (uint i; i < t; i++) {
            require(
                CurveBabyJubJub.isOnCurve(
                    _round1Contribution.x[i],
                    _round1Contribution.y[i]
                )
            );
        }

        distributedKey.round1Counter += 1;
        distributedKey.round1DataSubmissions.push(
            Round1DataSubmission(
                msg.sender,
                distributedKey.round1Counter,
                _round1Contribution.x,
                _round1Contribution.y
            )
        );
        (distributedKey.publicKeyX, distributedKey.publicKeyY) = CurveBabyJubJub
            .pointAdd(
                distributedKey.publicKeyX,
                distributedKey.publicKeyY,
                _round1Contribution.x[0],
                _round1Contribution.y[0]
            );

        emit Round1DataSubmitted(msg.sender);
        return distributedKey.round1Counter;
    }

    function submitRound2Contribution(
        uint256 _distributedKeyID,
        Round2Contribution calldata _round2Contribution
    ) external override onlyCommittee {
        DistributedKey storage distributedKey = distributedKeys[
            _distributedKeyID
        ];
        (uint8 t, uint8 n) = IFundManager(owner).getDKGParams();
        require(
            getDistributedKeyState(_distributedKeyID) ==
                DistributedKeyState.CONTRIBUTION_ROUND_2,
            "dkgContract: key's state is not CONTRIBUTION_ROUND_2"
        );
        require(
            _round2Contribution.recipientIndexes.length == n - 1 &&
                _round2Contribution.ciphers.length == n - 1,
            "dkgContract: invalid input length"
        );
        require(
            distributedKey
                .round1DataSubmissions[_round2Contribution.senderIndex - 1]
                .sender == msg.sender,
            "dkgContract: invalid sender"
        );

        bytes32 bitChecker;
        bytes32 bitMask;
        bitChecker = bitChecker | bytes32(1 << _round2Contribution.senderIndex);
        bitMask = bitMask | bytes32(1 << n);
        for (
            uint8 i = 0;
            i < _round2Contribution.recipientIndexes.length;
            i++
        ) {
            require(
                _round2Contribution.ciphers[i].length == 3,
                "dkgContract: invalid input length"
            );
            bitChecker =
                bitChecker |
                bytes32(1 << _round2Contribution.recipientIndexes[i]);
            bitMask = bitMask | bytes32(1 << (i + 1));
        }
        require(bitChecker == bitMask, "dkgContract: invalid recipientIndexes");

        uint256[] memory publicInputs = new uint256[](
            IVerifier(round2Verifier).getPublicInputsLength()
        );
        Round1DataSubmission memory senderSubmission = distributedKey
            .round1DataSubmissions[_round2Contribution.senderIndex - 1];
        for (
            uint8 i = 0;
            i < _round2Contribution.recipientIndexes.length;
            i++
        ) {
            Round1DataSubmission memory recipientSubmission = distributedKey
                .round1DataSubmissions[
                    _round2Contribution.recipientIndexes[i] - 1
                ];
            publicInputs[i] = _round2Contribution.recipientIndexes[i];
            publicInputs[n - 1 + i * 2] = recipientSubmission.x[0];
            publicInputs[n - 1 + i * 2 + 1] = recipientSubmission.y[0];
            publicInputs[(n - 1) * 3 + i * 2] = _round2Contribution.ciphers[i][
                0
            ];
            publicInputs[(n - 1) * 3 + i * 2 + 1] = _round2Contribution.ciphers[
                i
            ][1];
            publicInputs[(n - 1) * 5 + i] = _round2Contribution.ciphers[i][2];
        }

        for (uint8 i; i < t; i++) {
            publicInputs[(n - 1) * 6 + i * 2] = senderSubmission.x[i];
            publicInputs[(n - 1) * 6 + i * 2 + 1] = senderSubmission.y[i];
        }

        require(
            _verifyProof(
                round2Verifier,
                _round2Contribution.proof,
                publicInputs
            ),
            "dkgContract: invalid proof"
        );

        for (
            uint8 i = 0;
            i < _round2Contribution.recipientIndexes.length;
            i++
        ) {
            distributedKey
                .round2DataSubmissions[_round2Contribution.recipientIndexes[i]]
                .push(
                    Round2DataSubmission(
                        _round2Contribution.senderIndex,
                        _round2Contribution.ciphers[i]
                    )
                );
        }

        distributedKey.round2Counter += 1;
        emit Round2DataSubmitted(msg.sender);
        if (distributedKey.round2Counter == n) {
            emit DistributedKeyActivated(_distributedKeyID);
        }
    }

    // FIXME add checking whitelisted DAO later
    function startTallying(
        bytes32 _requestID,
        uint256 _distributedKeyID,
        uint256[][] memory _R,
        uint256[][] memory _M
    ) external override {
        TallyTracker storage tallyTracker = tallyTrackers[_requestID];
        require(tallyTracker.dao == address(0));
        tallyTracker.distributedKeyID = _distributedKeyID;
        tallyTracker.R = _R;
        tallyTracker.M = _M;
        uint8 dimension = distributedKeys[_distributedKeyID].dimension;
        address tallyContributionVerifier = address(
            tallyContributionVerifiers[dimension]
        );
        address resultVerifier = address(resultVerifiers[dimension]);
        require(tallyContributionVerifier != address(0));
        require(resultVerifier != address(0));
        tallyTracker.dao = msg.sender;
        tallyTracker.contributionVerifier = tallyContributionVerifier;
        tallyTracker.resultVerifier = resultVerifier;

        emit TallyStarted(_requestID);
    }

    function submitTallyContribution(
        bytes32 _requestID,
        TallyContribution calldata _tallyContribution
    ) external override onlyCommittee {
        TallyTracker storage tallyTracker = tallyTrackers[_requestID];
        DistributedKey storage distributedKey = distributedKeys[
            tallyTracker.distributedKeyID
        ];
        (uint8 t, uint8 n) = IFundManager(owner).getDKGParams();
        uint8 dimension = distributedKey.dimension;

        require(
            getTallyTrackerState(_requestID) == TallyTrackerState.CONTRIBUTION
        );
        require(
            _tallyContribution.senderIndex >= 1 &&
                _tallyContribution.senderIndex <= n
        );
        require(_tallyContribution.Di.length == dimension);

        Round1DataSubmission memory round1DataSubmission = distributedKey
            .round1DataSubmissions[_tallyContribution.senderIndex - 1];
        Round2DataSubmission[] memory round2DataSubmissions = distributedKey
            .round2DataSubmissions[_tallyContribution.senderIndex];
        IVerifier verifier = IVerifier(tallyTracker.contributionVerifier);
        uint[] memory publicInputs = new uint[](
            verifier.getPublicInputsLength()
        );

        n = n - 1;
        publicInputs[0] = _tallyContribution.senderIndex;
        for (uint8 i; i < t; i++) {
            publicInputs[2 * i + 1] = round1DataSubmission.x[i];
            publicInputs[2 * i + 1 + 1] = round1DataSubmission.y[i];
        }
        for (uint8 i; i < n; i++) {
            publicInputs[2 * i + 2 * t + 1] = round2DataSubmissions[i].ciphers[
                0
            ];
            publicInputs[2 * i + 1 + 2 * t + 1] = round2DataSubmissions[i]
                .ciphers[1];
            publicInputs[2 * n + i + 2 * t + 1] = round2DataSubmissions[i]
                .ciphers[2];
        }
        for (uint8 i; i < dimension; i++) {
            publicInputs[3 * n + 2 * i + 2 * t + 1] = tallyTracker.R[i][0];
            publicInputs[3 * n + 2 * i + 1 + 2 * t + 1] = tallyTracker.R[i][1];
            publicInputs[
                3 * n + dimension * 2 + 2 * i + 2 * t + 1
            ] = _tallyContribution.Di[i][0];
            publicInputs[
                3 * n + dimension * 2 + 2 * i + 1 + 2 * t + 1
            ] = _tallyContribution.Di[i][1];
        }

        // Verify proof
        _verifyProof(verifier, _tallyContribution.proof, publicInputs);

        tallyTracker.tallyDataSubmissions.push(
            TallyDataSubmission(
                _tallyContribution.senderIndex,
                _tallyContribution.Di
            )
        );
        tallyTracker.tallyCounter += 1;

        emit TallyContributionSubmitted(msg.sender);
    }

    function submitTallyResult(
        bytes32 _requestID,
        uint256[] calldata _result,
        bytes calldata _proof
    ) external override {
        TallyTracker storage tallyTracker = tallyTrackers[_requestID];
        require(
            getTallyTrackerState(_requestID) ==
                TallyTrackerState.RESULT_AWAITING
        );
        DistributedKey storage distributedKey = distributedKeys[
            tallyTracker.distributedKeyID
        ];
        uint8 dimension = distributedKey.dimension;
        (uint8 t, ) = IFundManager(owner).getDKGParams();

        // Verify result
        uint256[] memory publicInputs = new uint256[](
            IVerifier(tallyTracker.resultVerifier).getPublicInputsLength()
        );
        TallyDataSubmission[] memory tallyDataSubmissions = tallyTracker
            .tallyDataSubmissions;
        uint256[][] memory M = tallyTracker.M;
        for (uint8 i; i < t; i++) {
            publicInputs[i] = tallyDataSubmissions[i].senderIndex;
            for (uint8 j; j < dimension; j++) {
                publicInputs[
                    t + i * dimension * 2 + 2 * j
                ] = tallyDataSubmissions[i].Di[j][0];
                publicInputs[
                    t + i * dimension * 2 + 2 * j + 1
                ] = tallyDataSubmissions[i].Di[j][1];
                // console.log("%d", t + i * dimension * 2 + 2 * j);
                // console.log("%d", t + i * dimension * 2 + 2 * j + 1);
            }
        }
        for (uint8 i; i < dimension; i++) {
            publicInputs[t + t * dimension * 2 + 2 * i] = M[i][0];
            publicInputs[t + t * dimension * 2 + 2 * i + 1] = M[i][1];
            publicInputs[t + t * dimension * 2 + 2 * dimension + i] = _result[
                i
            ];
        }
        require(
            _verifyProof(
                IVerifier(tallyTracker.resultVerifier),
                _proof,
                publicInputs
            )
        );

        IDKGRequest(tallyTracker.dao).submitTallyResult(_requestID, _result);
        distributedKey.usageCounter += 1;
        tallyTracker.resultSubmitted = true;

        emit TallyResultSubmitted(msg.sender, _requestID, _result);
    }

    /*==================== VIEW FUNCTION ====================*/

    function getUsageCounter(
        uint256 _distributedKeyID
    ) external view override returns (uint256) {
        return distributedKeys[_distributedKeyID].usageCounter;
    }

    function getDimension(
        uint256 _distributedKeyID
    ) external view override returns (uint8) {
        return distributedKeys[_distributedKeyID].dimension;
    }

    function getDistributedKeyState(
        uint256 _distributedKeyID
    ) public view override returns (DistributedKeyState) {
        DistributedKey storage distributedKey = distributedKeys[
            _distributedKeyID
        ];
        (, uint8 n) = IFundManager(owner).getDKGParams();
        if (distributedKey.round2Counter == n) {
            return DistributedKeyState.ACTIVE;
        }
        if (distributedKey.round1Counter == n) {
            return DistributedKeyState.CONTRIBUTION_ROUND_2;
        }
        return DistributedKeyState.CONTRIBUTION_ROUND_1;
    }

    function getType(
        uint256 _distributedKeyID
    ) external view override returns (DistributedKeyType) {
        return distributedKeys[_distributedKeyID].keyType;
    }

    function getCommitteeIndex(
        address _committeeAddress,
        uint256 _distributedKeyID
    ) external view override returns (uint8) {
        require(
            getDistributedKeyState(_distributedKeyID) >
                DistributedKeyState.CONTRIBUTION_ROUND_1,
            "dkgContract: not done CONTRIBUTION_ROUND_1"
        );
        Round1DataSubmission[] memory round1DataSubmissions = distributedKeys[
            _distributedKeyID
        ].round1DataSubmissions;
        for (uint8 i = 0; i < round1DataSubmissions.length; i++) {
            if (round1DataSubmissions[i].sender == _committeeAddress)
                return i + 1;
        }
        revert("dkgContract: invalid _committeeAddress");
    }

    function getRound1DataSubmissions(
        uint256 _distributedKeyID
    ) external view override returns (Round1DataSubmission[] memory) {
        return distributedKeys[_distributedKeyID].round1DataSubmissions;
    }

    function getRound2DataSubmissions(
        uint256 _distributedKeyID,
        uint8 _recipientIndex
    ) external view override returns (Round2DataSubmission[] memory) {
        return
            distributedKeys[_distributedKeyID].round2DataSubmissions[
                _recipientIndex
            ];
    }

    function getPublicKey(
        uint256 _distributedKeyID
    ) external view override returns (uint256, uint256) {
        DistributedKey storage distributedKey = distributedKeys[
            _distributedKeyID
        ];
        require(
            getDistributedKeyState(_distributedKeyID) ==
                DistributedKeyState.ACTIVE
        );
        return (distributedKey.publicKeyX, distributedKey.publicKeyY);
    }

    function getVerifier(
        uint256 _distributedKeyID
    ) external view override returns (IVerifier) {
        DistributedKey storage distributedKey = distributedKeys[
            _distributedKeyID
        ];
        return IVerifier(distributedKey.verifier);
    }

    function getTallyTracker(
        bytes32 _requestID
    ) external view override returns (TallyTracker memory) {
        return tallyTrackers[_requestID];
    }

    function getTallyTrackerState(
        bytes32 _requestID
    ) public view override returns (TallyTrackerState) {
        TallyTracker memory tallyTracker = tallyTrackers[_requestID];
        (uint8 t, ) = IFundManager(owner).getDKGParams();

        if (tallyTracker.resultSubmitted) {
            return TallyTrackerState.RESULT_SUBMITTED;
        }
        if (tallyTracker.tallyCounter == t) {
            return TallyTrackerState.RESULT_AWAITING;
        }
        return TallyTrackerState.CONTRIBUTION;
    }

    function getTallyDataSubmissions(
        bytes32 _requestID
    ) external view override returns (TallyDataSubmission[] memory) {
        return tallyTrackers[_requestID].tallyDataSubmissions;
    }

    function getR(
        bytes32 _requestID
    ) external view override returns (uint256[][] memory) {
        return tallyTrackers[_requestID].R;
    }

    function getM(
        bytes32 _requestID
    ) external view override returns (uint256[][] memory) {
        return tallyTrackers[_requestID].M;
    }

    // function getResultVector(
    //     bytes32 _requestID
    // ) public view override returns (uint256[][] memory) {
    //     TallyTracker memory tallyTracker = tallyTrackers[_requestID];
    //     DistributedKey storage distributedKey = distributedKeys[
    //         tallyTracker.distributedKeyID
    //     ];
    //     require(
    //         getTallyTrackerState(_requestID) ==
    //             TallyTrackerState.RESULT_AWAITING
    //     );
    //     uint8 dimension = distributedKey.dimension;
    //     (uint8 t, ) = IFundManager(owner).getDKGParams();

    //     uint256[] memory sumDx = new uint256[](dimension);
    //     uint256[] memory sumDy = new uint256[](dimension);
    //     uint256[][] memory M = tallyTracker.M;

    //     uint8[] memory listIndex = new uint8[](t);
    //     for (uint8 i; i < t; i++) {
    //         listIndex[i] = tallyTracker.tallyDataSubmissions[i].senderIndex;
    //     }

    //     uint256[] memory lagrangeCoefficient = Math.computeLagrangeCoefficient(
    //         listIndex,
    //         t
    //     );
    //     for (uint8 i; i < dimension; i++) {
    //         sumDx[i] = 0;
    //         sumDy[i] = 1;
    //     }
    //     for (uint8 i; i < t; i++) {
    //         TallyDataSubmission memory tallyDataSubmission = tallyTracker
    //             .tallyDataSubmissions[i];
    //         for (uint8 j; j < dimension; j++) {
    //             (uint256 tmpX, uint256 tmpY) = CurveBabyJubJub.pointMul(
    //                 tallyDataSubmission.Di[j][0],
    //                 tallyDataSubmission.Di[j][1],
    //                 lagrangeCoefficient[i]
    //             );
    //             (sumDx[j], sumDy[j]) = CurveBabyJubJub.pointAdd(
    //                 sumDx[j],
    //                 sumDy[j],
    //                 tmpX,
    //                 tmpY
    //             );
    //         }
    //     }

    //     uint256[][] memory tallyResultVector = new uint256[][](dimension);
    //     for (uint8 i; i < dimension; i++) {
    //         sumDx[i] = CurveBabyJubJub.Q - sumDx[i];
    //         (uint256 tmpX, uint256 tmpY) = CurveBabyJubJub.pointAdd(
    //             sumDx[i],
    //             sumDy[i],
    //             M[i][0],
    //             M[i][1]
    //         );
    //         tallyResultVector[i] = new uint256[](2);
    //         tallyResultVector[i][0] = tmpX;
    //         tallyResultVector[i][1] = tmpY;
    //     }

    //     return tallyResultVector;
    // }

    /*================== INTERNAL FUNCTION ==================*/

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
}
