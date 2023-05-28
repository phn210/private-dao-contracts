// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDKG.sol";
import "./interfaces/IVerifier.sol";
import "./interfaces/IFundManager.sol";
import "./interfaces/IDKGRequest.sol";
import "./libs/CurveBabyJubJub.sol";
import "./libs/Math.sol";

contract DKG is IDKG {
    address public owner;
    uint256 round1Period;
    uint256 round2Period;
    uint256 distributedKeyCounter;

    mapping(uint256 => DistributedKey) public distributedKeys;
    mapping(bytes32 => TallyTracker) public tallyTrackers;      // rename

    IVerifier public round2Verifier;
    // dimension => Verifier
    mapping(uint256 => IVerifier) public fundingVerifiers;
    mapping(uint256 => IVerifier) public votingVerifiers;
    mapping(uint256 => IVerifier) public tallyContributionVerifiers;
    mapping(uint256 => IVerifier) public tallyResultContributionVerifiers;
    mapping(uint256 => IVerifier) public resultVerifiers;

    constructor(DKGConfig memory _dkgConfig) {
        owner = msg.sender;
        round1Period = _dkgConfig.round1Period;
        round2Period = _dkgConfig.round2Period;
        round2Verifier = IVerifier(_dkgConfig.round2Verfier);
        fundingVerifiers[3] = IVerifier(_dkgConfig.fundingVerifier);
        votingVerifiers[3] = IVerifier(_dkgConfig.votingVerifier);
        tallyContributionVerifiers[3] = IVerifier(
            _dkgConfig.tallyContributionVerfier
        );
        tallyResultContributionVerifiers[3] = IVerifier(
            _dkgConfig.tallyResultContributionVerifier
        );
        resultVerifiers[3] = IVerifier(_dkgConfig.resultVerifier);
    }

    modifier onlyOwner() override {
        require(msg.sender == owner, "DKG Contract: msg.sender is not owner");
        _;
    }

    modifier onlyCommittee() override {
        require(IFundManager(owner).isCommittee(msg.sender));
        _;
    }

    modifier onlyWhitelistedDAO() override {
        require(IFundManager(owner).isWhitelistedDAO(msg.sender));
        _;
    }

    function generateDistributedKey(
        uint8 _dimension,
        DistributedKeyType _distributedKeyType
    ) external override onlyOwner returns (uint256 distributedKeyID) {
        distributedKeyID = distributedKeyCounter;
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
                "DKG Contract: No funding verifier exists with corresponding dimensionality"
            );
            verifier = address(votingVerifiers[_dimension]);
        }
        distributedKey.keyType = _distributedKeyType;
        distributedKey.state = DistributedKeyState.ROUND_1_CONTRIBUTION;
        distributedKey.dimension = _dimension;
        distributedKey.verifier = verifier;
        distributedKey.publicKeyX = 0;
        distributedKey.publicKeyY = 1;
        distributedKey.startRound1Timestamp = block.timestamp;
        distributedKey.usageCounter = 0;
        distributedKeyCounter += 1;
    }

    function submitRound1Contribution(
        uint256 _distributedKeyID,
        uint256[] calldata _x,
        uint256[] calldata _y
    ) external override onlyCommittee returns (uint8) {
        DistributedKey storage distributedKey = distributedKeys[
            _distributedKeyID
        ];
        (uint8 t, uint8 n) = IFundManager(owner).getDKGParams();
        require(
            distributedKey.state == DistributedKeyState.ROUND_1_CONTRIBUTION
        );
        // if (
        //     distributedKey.startRound1Timestamp + round1Time > block.timestamp
        // ) {
        //     distributedKey.distributedKeyState = DistributedKeyState.FAILED;
        // }
        // FIXME put _x & _y in a struct => save gas fee to check length(x) == length(y)
        require(_x.length == _y.length && _x.length == t);

        for (uint i; i < t; i++) {
            require(CurveBabyJubJub.isOnCurve(_x[i], _y[i]));
        }
        distributedKey.round1Counter += 1;
        distributedKey.round1Contributions.push(
            Round1Contribution(msg.sender, distributedKey.round1Counter, _x, _y)
        );

        (distributedKey.publicKeyX, distributedKey.publicKeyY) = CurveBabyJubJub
            .pointAdd(
                distributedKey.publicKeyX,
                distributedKey.publicKeyY,
                _x[0],
                _y[0]
            );

        if (distributedKey.round1Counter == n) {
            distributedKey.state = DistributedKeyState.ROUND_2_CONTRIBUTION;
            distributedKey.startRound2Timestamp = block.timestamp;
        }

        return distributedKey.round1Counter;
    }

    function submitRound2Contribution(
        uint256 _distributedKeyID,
        uint8[] calldata _committeeIndexes,
        uint256[][] calldata _ciphers,
        bytes[] calldata _proofs
    ) external override onlyCommittee {
        DistributedKey storage distributedKey = distributedKeys[
            _distributedKeyID
        ];
        (uint8 t, uint8 n) = IFundManager(owner).getDKGParams();
        require(
            distributedKey.state == DistributedKeyState.ROUND_2_CONTRIBUTION
        );
        require(_committeeIndexes.length == n);
        require(_ciphers.length == 3);
        uint256 sum = 0;
        for (uint8 i = 0; i < _committeeIndexes.length; i++) {
            require(_committeeIndexes[i] >= 1 && _committeeIndexes[i] <= n);
            if (i != 0) {
                require(_committeeIndexes[i] != _committeeIndexes[0]);
            }
            sum += (uint256)(_committeeIndexes[i]);
        }
        require(sum == (n * (n + 1)) / 2);
        require(
            distributedKey.round1Contributions[_committeeIndexes[0]].sender ==
                msg.sender
        );
        // if (
        //     distributedKey.startRound2Timestamp + round2Time > block.timestamp
        // ) {
        //     distributedKey.distributedKeyState = DistributedKeyState.FAILED;
        // }
        uint256[] memory publicInputs = new uint256[](
            IVerifier(distributedKey.verifier).getPublicInputsLength()
        );
        for (uint8 i = 1; i < _committeeIndexes.length; i++) {
            publicInputs[0] = _committeeIndexes[i];
            publicInputs[1] = distributedKey
                .round1Contributions[_committeeIndexes[i] - 1]
                .x[0];
            publicInputs[2] = distributedKey
                .round1Contributions[_committeeIndexes[i] - 1]
                .y[0];
            for (uint8 j = 0; j < t; j++) {
                publicInputs[3 + j * 2] = distributedKey
                    .round1Contributions[_committeeIndexes[0]]
                    .x[j];
                publicInputs[3 + j * 2 + 1] = distributedKey
                    .round1Contributions[_committeeIndexes[0]]
                    .y[j];
            }
            publicInputs[3 + t * 2] = _ciphers[i][0];
            publicInputs[3 + t * 2 + 1] = _ciphers[i][1];
            publicInputs[3 + t * 2 + 2] = _ciphers[i][2];

            require(_verifyProof(round2Verifier, _proofs[i], publicInputs));

            distributedKey.round2Contributions[_committeeIndexes[i]].push(
                Round2Contribution(_committeeIndexes[0], _ciphers[i])
            );
        }

        distributedKey.round2Counter += 1;
        if (distributedKey.round2Counter == n) {
            distributedKey.state == DistributedKeyState.MAIN;   // FIXME
        }
    }

    function startTallying(
        bytes32 _requestID,
        uint256 _distributedKeyID,
        uint256[][] memory _R,
        uint256[][] memory _M
    ) external override onlyWhitelistedDAO {
        TallyTracker storage tallyTracker = tallyTrackers[_requestID];
        require(
            tallyTracker.tallyContributionVerifier == address(0) &&
                tallyTracker.tallyResultContributionVerifier == address(0) &&
                tallyTracker.resultVerifier == address(0)
        );
        tallyTracker.distributedKeyID = _distributedKeyID;
        tallyTracker.R = _R;
        tallyTracker.M = _M;
        uint8 dimension = distributedKeys[_distributedKeyID].dimension;
        address tallyContributionVerfier = address(
            tallyContributionVerifiers[dimension]
        );
        address tallyResultContributionVerifier = address(
            tallyResultContributionVerifiers[dimension]
        );
        address resultVerifier = address(resultVerifiers[dimension]);
        require(tallyContributionVerfier != address(0));
        require(tallyResultContributionVerifier != address(0));
        require(resultVerifier != address(0));
        tallyTracker.dao = msg.sender;
        tallyTracker.tallyContributionVerifier = tallyContributionVerfier;
        tallyTracker
            .tallyResultContributionVerifier = tallyResultContributionVerifier;
        tallyTracker.resultVerifier = resultVerifier;
        tallyTracker.state = TallyTrackerState.TALLY_CONTRIBUTION;
    }

    function submitTallyContribution(
        bytes32 _requestID,
        uint8 _senderIndex,
        uint256[][] calldata _Di,
        bytes calldata _proof
    ) external override onlyCommittee {
        TallyTracker storage tallyTracker = tallyTrackers[_requestID];
        DistributedKey storage distributedKey = distributedKeys[
            tallyTracker.distributedKeyID
        ];
        (uint8 t, uint8 n) = IFundManager(owner).getDKGParams();
        uint8 dimension = distributedKey.dimension;

        require(tallyTracker.state == TallyTrackerState.TALLY_CONTRIBUTION);
        require(_senderIndex >= 1 && _senderIndex <= n);
        require(_Di.length == dimension);

        n = n - 1;
        Round2Contribution[] storage round2Contributions = distributedKey
            .round2Contributions[_senderIndex];
        IVerifier verifier = IVerifier(tallyTracker.tallyContributionVerifier);
        uint[] memory publicInputs = new uint[](
            verifier.getPublicInputsLength()
        );
        for (uint8 i; i < n; i++) {
            publicInputs[2 * i] = round2Contributions[i].cipher[0];
            publicInputs[2 * i + 1] = round2Contributions[i].cipher[1];
            publicInputs[2 * n + i] = round2Contributions[i].cipher[2];
        }
        for (uint8 i; i < dimension; i++) {
            publicInputs[3 * n + 2 * i] = tallyTracker.R[i][0];
            publicInputs[3 * n + 2 * i + 1] = tallyTracker.R[i][1];
            publicInputs[3 * n + dimension * 2 + 2 * i] = _Di[i][0];
            publicInputs[3 * n + dimension * 2 + 2 * i + 1] = _Di[i][1];
        }

        // Verify proof
        _verifyProof(verifier, _proof, publicInputs);

        tallyTracker.tallyContributions.push(
            TallyContribution(_senderIndex, _Di)
        );
        tallyTracker.tallyCounter += 1;
        if (tallyTracker.tallyCounter == t) {
            tallyTracker.state = TallyTrackerState.TALLY_RESULT_CONTRIBUTION;
        }
    }

    function submitTallyingResult(
        bytes32 _requestID,
        uint256[] calldata _result,
        bytes calldata _proof
    ) external override {
        TallyTracker storage tallyTracker = tallyTrackers[_requestID];
        require(
            tallyTracker.state == TallyTrackerState.TALLY_RESULT_CONTRIBUTION
        );
        DistributedKey storage distributedKey = distributedKeys[
            tallyTracker.distributedKeyID
        ];
        uint8 dimension = distributedKey.dimension;
        // Verify result
        uint256[][] memory resultVector = getTallyResultVector(_requestID);
        uint256[] memory publicInputs = new uint256[](
            IVerifier(tallyTracker.resultVerifier).getPublicInputsLength()
        );
        for (uint8 i = 0; i < dimension; i++) {
            publicInputs[i] = _result[i];
            publicInputs[dimension + 2 * i] = resultVector[i][0];
            publicInputs[dimension + 2 * i + 1] = resultVector[i][1];
        }

        require(
            _verifyProof(
                IVerifier(tallyTracker.resultVerifier),
                _proof,
                publicInputs
            )
        );
        IDKGRequest(tallyTracker.dao).submitTallyingResult(_requestID, _result);
        tallyTracker.state = TallyTrackerState.END;
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

    function getState(
        uint256 _distributedKeyID
    ) external view override returns (DistributedKeyState) {
        return distributedKeys[_distributedKeyID].state;
    }

    function getType(
        uint256 _distributedKeyID
    ) external view override returns (DistributedKeyType) {
        return distributedKeys[_distributedKeyID].keyType;
    }

    function getRound1Contribution(
        uint256 _distributedKeyID,
        uint8 _senderIndex
    ) external view override returns (Round1Contribution memory) {
        return
            distributedKeys[_distributedKeyID].round1Contributions[
                _senderIndex - 1
            ];
    }

    function getPublicKey(
        uint256 _distributedKeyID
    ) external view override returns (uint256, uint256) {
        DistributedKey storage distributedKey = distributedKeys[
            _distributedKeyID
        ];
        require(distributedKey.state == DistributedKeyState.MAIN);
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

    function getTallyResultVector(
        bytes32 _requestID
    ) public view override returns (uint256[][] memory) {
        TallyTracker memory tallyTracker = tallyTrackers[_requestID];
        DistributedKey storage distributedKey = distributedKeys[
            tallyTracker.distributedKeyID
        ];
        require(
            tallyTracker.state == TallyTrackerState.TALLY_RESULT_CONTRIBUTION
        );
        uint8 dimension = distributedKey.dimension;
        (uint8 t, ) = IFundManager(owner).getDKGParams();

        uint256[] memory sumDx = new uint256[](dimension);
        uint256[] memory sumDy = new uint256[](dimension);
        uint256[][] memory M = tallyTracker.M;

        uint8[] memory listIndex = new uint8[](t);
        for (uint8 i; i < t; i++) {
            listIndex[i] = tallyTracker.tallyContributions[i].i;
        }

        uint256[] memory lagrangeCoefficient = Math.computeLagrangeCoefficient(
            listIndex,
            t
        );
        for (uint8 i; i < dimension; i++) {
            sumDx[i] = 0;
            sumDy[i] = 1;
        }
        for (uint8 i; i < t; i++) {
            TallyContribution memory tallyContribution = tallyTracker
                .tallyContributions[i];
            for (uint8 j; j < dimension; j++) {
                (uint256 tmpX, uint256 tmpY) = CurveBabyJubJub.pointMul(
                    tallyContribution.Di[j][0],
                    tallyContribution.Di[j][1],
                    lagrangeCoefficient[i]
                );
                (sumDx[j], sumDy[j]) = CurveBabyJubJub.pointAdd(
                    sumDx[j],
                    sumDy[j],
                    tmpX,
                    tmpY
                );
            }
        }

        uint256[][] memory tallyResultVector = new uint256[][](dimension);
        for (uint8 i; i < dimension; i++) {
            sumDx[i] = CurveBabyJubJub.Q - sumDx[i];
            (uint256 tmpX, uint256 tmpY) = CurveBabyJubJub.pointAdd(
                sumDx[i],
                sumDy[i],
                M[i][0],
                M[i][1]
            );
            tallyResultVector[i] = new uint256[](2);
            tallyResultVector[i][0] = tmpX;
            tallyResultVector[i][1] = tmpY;
        }

        return tallyResultVector;
    }

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
