// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./interfaces/IFundManager.sol";
import "./interfaces/IDKGRequest.sol";
import "./interfaces/IDKG.sol";
import "./libs/Queue.sol";
import "./libs/Math.sol";

import "./libs/MerkleTree.sol";
import "./DKG.sol";

contract FundManager is
    IFundManager,
    IDKGRequest,
    MerkleTree,
    AutomationCompatibleInterface
{
    address public founder;
    uint8 public numberOfCommittees;
    uint8 public threshold;
    bool public fundingRoundInProgress;
    address public daoManager;
    uint256 public reserveFactor;
    FundingRoundConfig public config;
    uint256 public bounty;

    mapping(address => bool) public override isCommittee;
    // mapping(address => bool) public override isWhitelistedDAO;

    mapping(bytes32 => Request) public requests;
    mapping(uint256 => FundingRound) public fundingRounds;
    uint256 public fundingRoundCounter;

    Queue public fundingRoundQueue;
    IDKG public dkgContract;

    constructor(
        address[] memory _committeeList,
        address _daoManager,
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
        require(
            _daoManager != address(0),
            "FundManager: DAOManager can not be address 0"
        );

        founder = msg.sender;
        daoManager = _daoManager;

        for (uint256 i = 0; i < _committeeList.length; i++) {
            isCommittee[_committeeList[i]] = true;
        }
        numberOfCommittees = (uint8)(_committeeList.length);
        threshold = numberOfCommittees / 2 + 1;
        // isWhitelistedDAO[address(this)] = true;
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

    modifier onlyDAOManager() override {
        require(msg.sender == daoManager);
        _;
    }

    modifier onlyDKG() override {
        require(msg.sender == address(dkgContract));
        _;
    }

    /*================== EXTERNAL FUNCTION ==================*/

    function applyForFunding(address _dao) external override onlyDAOManager {
        fundingRoundQueue.enqueue(_dao);

        emit FundingRoundApplied(_dao);
    }

    function launchFundingRound(
        uint256 _distributedKeyID
    ) external override returns (uint256 fundingRoundID, bytes32 requestID) {
        require(
            !fundingRoundInProgress,
            "FundManager: is having a funding round in progress"
        );
        require(
            dkgContract.getDistributedKeyState(_distributedKeyID) ==
                IDKG.DistributedKeyState.ACTIVE &&
                dkgContract.getType(_distributedKeyID) ==
                IDKG.DistributedKeyType.FUNDING &&
                dkgContract.getUsageCounter(_distributedKeyID) == 0,
            "FundManager: Invalid key"
        );
        uint8 dimension = dkgContract.getDimension(_distributedKeyID);
        require(
            fundingRoundQueue.getLength() >= dimension,
            "FundManager: The dimension of the key does not satisfy the number of DAOs"
        );
        address[] memory listDAO = new address[](dimension);
        for (uint8 i = 0; i < listDAO.length; i++) {
            listDAO[i] = fundingRoundQueue.dequeue();
        }

        FundingRound storage fundingRound = fundingRounds[fundingRoundCounter];
        fundingRoundID = fundingRoundCounter;
        fundingRoundCounter += 1;
        requestID = getRequestID(
            _distributedKeyID,
            address(this),
            fundingRoundID
        );

        Request storage request = requests[requestID];
        request.distributedKeyID = _distributedKeyID;
        for (uint8 i; i < dimension; i++) {
            request.R.push([0, 1]);
            request.M.push([0, 1]);
        }

        fundingRound.requestID = requestID;
        fundingRound.listDAO = listDAO;
        fundingRound.launchedAt = uint64(block.number);

        fundingRoundInProgress = true;

        emit FundingRoundLaunched(fundingRoundID, requestID);
    }

    function fund(
        uint256 _fundingRoundID,
        uint256 _commitment,
        uint256[][] calldata _R,
        uint256[][] calldata _M,
        bytes calldata _proof
    ) external payable override {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundID];
        require(
            getFundingRoundState(_fundingRoundID) == FundingRoundState.ACTIVE,
            "FundManager: FundingRound is not active"
        );
        Request storage request = requests[fundingRound.requestID];
        uint8 dimension = dkgContract.getDimension(request.distributedKeyID);
        require(
            _R.length == dimension && _M.length == dimension,
            "FundManager: invalid input length"
        );
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
        fundingRound.balance += msg.value;
        fundingRound.balances[msg.sender] += msg.value;

        emit Funded(_fundingRoundID, msg.sender, msg.value, _commitment);
    }

    function startTallying(uint256 _fundingRoundID) public override {
        bytes32 requestID = fundingRounds[_fundingRoundID].requestID;
        require(
            getFundingRoundState(_fundingRoundID) ==
                FundingRoundState.TALLYING &&
                dkgContract.getTallyTracker(requestID).contributionVerifier ==
                address(0) &&
                dkgContract.getTallyTracker(requestID).resultVerifier ==
                address(0)
        );
        Request memory request = requests[requestID];
        dkgContract.startTallying(
            requestID,
            request.distributedKeyID,
            request.R,
            request.M
        );

        emit TallyStarted(_fundingRoundID, requestID);
    }

    function submitTallyResult(
        bytes32 _requestID,
        uint256[] calldata _result
    ) external override onlyDKG {
        Request storage request = requests[_requestID];
        require(request.respondedAt == 0);
        request.result = _result;
        request.respondedAt = block.number;

        emit TallyResultSubmitted(_requestID, _result);
    }

    function finalizeFundingRound(uint256 _fundingRoundID) external override {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundID];
        Request memory request = requests[fundingRound.requestID];

        if (
            getFundingRoundState(_fundingRoundID) == FundingRoundState.FAILED &&
            fundingRound.failedAt == 0
        ) {
            fundingRound.failedAt = uint64(block.number);
            delete fundingRound.listCommitment;
            fundingRoundInProgress = false;

            emit FundingRoundFailed(_fundingRoundID);
        } else if (
            getFundingRoundState(_fundingRoundID) == FundingRoundState.SUCCEEDED
        ) {
            // _insertBatch(fundingRound.listCommitment);
            for (uint256 i; i < fundingRound.listCommitment.length; i++) {
                uint32 index = _insert(fundingRound.listCommitment[i]);
                emit LeafInserted(index, fundingRound.listCommitment[i]);
            }
            for (uint8 i; i < fundingRound.listDAO.length; i++) {
                fundingRound.daoBalances[fundingRound.listDAO[i]] = request
                    .result[i];
            }
            delete fundingRound.listCommitment;
            fundingRound.finalizedAt = uint64(block.number);

            fundingRoundInProgress = false;
            emit FundingRoundFinalized(_fundingRoundID);
        } else {
            revert();
        }
    }

    function refund(uint256 _fundingRoundID) external override {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundID];
        require(
            getFundingRoundState(_fundingRoundID) == FundingRoundState.FAILED
        );
        uint256 balance = fundingRound.balances[msg.sender];
        fundingRound.balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);

        emit Refunded(_fundingRoundID, msg.sender, balance);
    }

    function withdrawFund(
        uint256 _fundingRoundID,
        address _dao
    ) external override {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundID];
        require(
            getFundingRoundState(_fundingRoundID) == FundingRoundState.FINALIZED
        );
        require(
            fundingRound.daoBalances[_dao] > 0,
            "FundManager: does not have fund to withdraw"
        );
        uint256 reserveAmount = (fundingRound.daoBalances[_dao] *
            reserveFactor) / 10 ** 18;
        bounty += reserveAmount;
        uint256 withdrawAmount = fundingRound.daoBalances[_dao] - reserveAmount;
        fundingRound.daoBalances[_dao] = 0;
        payable(_dao).transfer(withdrawAmount);

        emit FundWithdrawed(_fundingRoundID, _dao, withdrawAmount);
    }

    /*==================== VIEW FUNCTION ====================*/

    function getFundingRoundQueueLength()
        external
        view
        override
        returns (uint256)
    {
        return fundingRoundQueue.getLength();
    }

    // FIXME use a funding round counter instead of timestamp for determinism
    function getRequestID(
        uint256 _distributedKeyID,
        address _requestor,
        uint256 _nonce
    ) public pure override returns (bytes32) {
        return
            keccak256(abi.encodePacked(_distributedKeyID, _requestor, _nonce));
    }

    function isFounder(address _sender) external view override returns (bool) {
        return _sender == founder;
    }

    function getDKGParams() external view override returns (uint8, uint8) {
        return (threshold, numberOfCommittees);
    }

    function getListDAO(
        uint256 _fundingRoundID
    ) external view override returns (address[] memory) {
        return fundingRounds[_fundingRoundID].listDAO;
    }

    function getFundingRoundBalance(
        uint256 _fundingRoundID
    ) external view override returns (uint256) {
        return fundingRounds[_fundingRoundID].balance;
    }

    function getDistributedKeyID(
        bytes32 _requestID
    ) external view override returns (uint256) {
        return requests[_requestID].distributedKeyID;
    }

    function getFundingRoundState(
        uint256 _fundingRoundID
    ) public view returns (FundingRoundState) {
        require(
            _fundingRoundID < fundingRoundCounter,
            "FundManager: invalid fundingRoundID"
        );
        uint64 finalizedAt = fundingRounds[_fundingRoundID].finalizedAt;
        uint64 launchedAt = fundingRounds[_fundingRoundID].launchedAt;
        bytes32 requestID = fundingRounds[_fundingRoundID].requestID;
        Request memory request = requests[requestID];
        uint64 endPending = launchedAt + config.pendingPeriod;
        uint64 endActive = endPending + config.activePeriod;
        uint64 endTallying = endActive + config.tallyPeriod;
        if (finalizedAt != 0) {
            return FundingRoundState.FINALIZED;
        }
        if (block.number <= endPending) {
            return FundingRoundState.PENDING;
        }
        if (endPending < block.number && block.number <= endActive) {
            return FundingRoundState.ACTIVE;
        }
        if (
            endActive < request.respondedAt &&
            request.respondedAt <= endTallying
        ) {
            return FundingRoundState.SUCCEEDED;
        }
        if (endActive < block.number && block.number <= endTallying) {
            return FundingRoundState.TALLYING;
        }
        return FundingRoundState.FAILED;
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

    function getResult(
        bytes32 _requestID
    ) external view override returns (uint256[] memory) {
        return requests[_requestID].result;
    }

    /*================= CHAINLINK AUTOMATION =================*/
    function checkUpkeep(
        bytes calldata checkData
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 fundingRoundID = fundingRoundCounter - 1;
        bytes32 requestID = fundingRounds[fundingRoundID].requestID;
        if (
            getFundingRoundState(fundingRoundID) ==
            FundingRoundState.TALLYING &&
            dkgContract.getTallyTracker(requestID).dao == address(0)
        ) {
            upkeepNeeded = true;
            performData = bytes.concat(bytes32(fundingRoundID));
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 fundingRoundID = fundingRoundCounter - 1;
        bytes32 requestID = fundingRounds[fundingRoundID].requestID;
        if (
            getFundingRoundState(fundingRoundID) ==
            FundingRoundState.TALLYING &&
            dkgContract.getTallyTracker(requestID).dao == address(0)
        ) {
            uint256[1] memory data = abi.decode(performData, (uint256[1]));
            require(data[0] == fundingRoundID);
            startTallying(data[0]);
        }
    }
}
