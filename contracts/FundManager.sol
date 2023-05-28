// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFundManager.sol";
import "./interfaces/IDKGRequest.sol";
import "./interfaces/IDKG.sol";
import "./libs/Queue.sol";
import "./libs/Math.sol";

import "./libs/MerkleTree.sol";
import "./DKG.sol";

contract FundManager is IFundManager, IDKGRequest, MerkleTree {
    address public founder;
    uint8 public numberOfCommittees;
    uint8 public threshold;
    bool fundingRoundInProgress;
    uint256 public reserveFactor;
    FundingRoundConfig public config;
    uint256 public bounty;

    mapping(address => bool) public override isCommittee;
    mapping(address => bool) public override isWhitelistedDAO;

    mapping(bytes32 => Request) public requests;
    mapping(bytes32 => FundingRound) public fundingRounds;

    Queue public fundingRoundQueue;
    IDKG public dkgContract;

    constructor(
        address[] memory _committeeList,
        uint256 _reserveFactor,
        MerkleTreeConfig memory _merkleTreeConfig,
        FundingRoundConfig memory _fundingRoundConfig,
        IDKG.DKGConfig memory _dkgConfig
    )
        MerkleTree(
            _merkleTreeConfig.levels,
            IPoseidon(_merkleTreeConfig.poseidon)
        )
    {
        require(
            _committeeList.length >= 5,
            "FundManager contract: Require the number of committees greater than 5"
        );
        founder = msg.sender;

        for (uint256 i = 0; i < _committeeList.length; i++) {
            isCommittee[_committeeList[i]] = true;
        }
        numberOfCommittees = (uint8)(_committeeList.length);
        threshold = numberOfCommittees / 2 + 1;
        isWhitelistedDAO[address(this)] = true;
        reserveFactor = _reserveFactor;
        config = _fundingRoundConfig;
        fundingRoundQueue = new Queue(15);
        dkgContract = new DKG(_dkgConfig);
    }

    /*====================== MODIFIER ======================*/

    modifier onlyFounder() override {
        require(msg.sender == founder);
        _;
    }

    modifier onlyCommittee() override {
        require(isCommittee[msg.sender]);
        _;
    }

    modifier onlyWhitelistedDAO() override {
        require(isWhitelistedDAO[msg.sender]);
        _;
    }

    modifier onlyDKG() override {
        require(msg.sender == address(dkgContract));
        _;
    }

    /*================== EXTERNAL FUNCTION ==================*/

    function applyForFunding() external override onlyWhitelistedDAO {
        fundingRoundQueue.enqueue(msg.sender);
    }

    function launchFundingRound(
        uint256 _distributedKeyID
    ) external override onlyWhitelistedDAO returns (bytes32 requestID) {
        require(!fundingRoundInProgress);
        require(
            dkgContract.getState(_distributedKeyID) ==
                IDKG.DistributedKeyState.MAIN &&
                dkgContract.getType(_distributedKeyID) ==
                IDKG.DistributedKeyType.FUNDING &&
                dkgContract.getUsageCounter(_distributedKeyID) == 0
        );
        uint8 dimension = dkgContract.getDimension(_distributedKeyID);
        require(fundingRoundQueue.getLength() >= dimension);
        address[] memory listDAO = new address[](dimension);
        for (uint8 i = 0; i < listDAO.length; i++) {
            listDAO[i] = fundingRoundQueue.dequeue();
        }

        requestID = getRequestID(
            _distributedKeyID,
            address(this),
            block.timestamp
        );
        Request storage request = requests[requestID];
        request.distributedKeyID = _distributedKeyID;
        for (uint8 i; i < dimension; i++) {
            request.R[i][0] = 0;
            request.R[i][1] = 1;
            request.M[i][0] = 0;
            request.M[i][1] = 1;
        }

        FundingRound storage fundingRound = fundingRounds[requestID];
        fundingRound.listDAO = listDAO;
        fundingRound.state = FundingRoundState.PENDING;
        fundingRound.pendingStartBN = block.number;

        fundingRoundInProgress = true;
    }

    function fund(
        bytes32 _requestID,
        uint256 _commitment,
        uint256[][] calldata _R,
        uint256[][] calldata _M,
        bytes calldata _proof
    ) external payable override {
        Request storage request = requests[_requestID];
        FundingRound storage fundingRound = fundingRounds[_requestID];
        require(
            fundingRound.pendingStartBN + config.pendingPeriodBN < block.number
        );
        if (fundingRound.state == FundingRoundState.PENDING) {
            fundingRound.activeStartBN = block.number;
            fundingRound.state = FundingRoundState.ACTIVE;
        }
        require(
            fundingRound.state == FundingRoundState.ACTIVE &&
                fundingRound.activeStartBN + config.activePeriodBN >=
                block.number
        );

        uint8 dimension = dkgContract.getDimension(request.distributedKeyID);
        require(_R.length == dimension && _M.length == dimension);
        IVerifier verifier = dkgContract.getVerifier(request.distributedKeyID);
        uint256[] memory publicInputs = new uint256[](
            verifier.getPublicInputsLength()
        );
        (publicInputs[0], publicInputs[1]) = dkgContract.getPublicKey(
            request.distributedKeyID
        );
        publicInputs[2 + dimension] = msg.value;
        publicInputs[3 + dimension] = _commitment;

        for (uint8 i; i < dimension; i++) {
            publicInputs[2 + i] = (uint256)(uint160(fundingRound.listDAO[i]));
            publicInputs[4 + dimension + 2 * i] = _R[i][0];
            publicInputs[4 + dimension + 2 * i + 1] = _R[i][1];
            publicInputs[4 + 3 * dimension + 2 * i] = _M[i][0];
            publicInputs[4 + 3 * dimension + 2 * i + 1] = _M[i][1];
        }
        require(_verifyProof(verifier, _proof, publicInputs));
        for (uint8 i; i < dimension; i++) {
            (request.R[i][0], request.R[i][1]) = CurveBabyJubJub.pointAdd(
                request.R[i][0],
                request.R[i][1],
                _R[i][0],
                _R[i][1]
            );
            (request.M[i][0], request.M[i][1]) = CurveBabyJubJub.pointAdd(
                request.M[i][0],
                request.M[i][1],
                _M[i][0],
                _M[i][1]
            );
        }

        fundingRound.listCommitment.push(_commitment);
        fundingRound.balances[msg.sender] += msg.value;
    }

    function startTallying(bytes32 _requestID) external override {
        Request storage request = requests[_requestID];
        FundingRound storage fundingRound = fundingRounds[_requestID];
        require(
            fundingRound.state == FundingRoundState.ACTIVE &&
                fundingRound.activeStartBN + config.activePeriodBN <
                block.number
        );

        dkgContract.startTallying(
            _requestID,
            request.distributedKeyID,
            request.R,
            request.M
        );
        fundingRound.tallyStartBN = block.number;
        fundingRound.state = FundingRoundState.TALLYING;
    }

    function submitTallyingResult(
        bytes32 _requestID,
        uint256[] calldata _result
    ) external override onlyDKG {
        Request storage request = requests[_requestID];
        FundingRound storage fundingRound = fundingRounds[_requestID];
        require(
            fundingRound.state == FundingRoundState.TALLYING &&
                fundingRound.tallyStartBN + config.tallyingPeriodBN >=
                block.number
        );
        request.result = _result;
        fundingRound.succeededBN = block.number;
        fundingRound.state = FundingRoundState.SUCCEEDED;
    }

    function finalizeFundingRound(bytes32 _requestID) external override {
        Request storage request = requests[_requestID];
        FundingRound storage fundingRound = fundingRounds[_requestID];
        require(
            fundingRound.tallyStartBN + config.tallyingPeriodBN < block.number
        );
        if (fundingRound.state == FundingRoundState.TALLYING) {
            delete fundingRound.listCommitment;
            fundingRound.state = FundingRoundState.FAILED;
            fundingRound.failedBN = block.number;

            fundingRoundInProgress = false;
        } else if (fundingRound.state == FundingRoundState.SUCCEEDED) {
            for (uint256 i; i < fundingRound.listCommitment.length; i++) {
                _insert(fundingRound.listCommitment[i]);
            }
            for (uint8 i; i < fundingRound.listDAO.length; i++) {
                fundingRound.daoBalances[fundingRound.listDAO[i]] = request
                    .result[i];
            }
            delete fundingRound.listCommitment;
            fundingRound.state = FundingRoundState.FINALIZED;
            fundingRound.finalizedBN = block.number;

            fundingRoundInProgress = false;
        } else {
            revert();
        }
    }

    function refund(bytes32 _requestID) external override {
        FundingRound storage fundingRound = fundingRounds[_requestID];
        require(fundingRound.state == FundingRoundState.FAILED);
        uint256 balance = fundingRound.balances[msg.sender];
        fundingRound.balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function withdrawFund(bytes32 _requestID, address _dao) external override {
        FundingRound storage fundingRound = fundingRounds[_requestID];
        require(fundingRound.state == FundingRoundState.FINALIZED);
        require(fundingRound.daoBalances[_dao] > 0);
        uint256 reserveAmount = (fundingRound.daoBalances[_dao] *
            reserveFactor) / 10 ** 18;
        bounty += reserveAmount;
        uint256 withdrawAmount = fundingRound.daoBalances[_dao] - reserveAmount;
        fundingRound.daoBalances[_dao] = 0;
        payable(_dao).transfer(withdrawAmount);
    }

    /*==================== VIEW FUNCTION ====================*/

    // FIXME use a funding round counter instead of timestamp for determinism
    function getRequestID(
        uint256 _distributedKeyID,
        address _requestor,
        uint256 _nonce
    ) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(_distributedKeyID, _requestor, _nonce));
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

    function getDKGParams() external view override returns (uint8, uint8) {}

    function getRequest(
        bytes32 _requestID
    ) external view override returns (Request memory) {}

    function getDistributedKeyID(
        bytes32 _requestID
    ) external view override returns (uint256) {}

    function getR(
        bytes32 _requestID
    ) external view override returns (uint256[][] memory) {}

    function getM(
        bytes32 _requestID
    ) external view override returns (uint256[][] memory) {}
}
