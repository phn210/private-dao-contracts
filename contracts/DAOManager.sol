// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDAOFactory.sol";
import "./interfaces/IDKG.sol";
import "./interfaces/IFundManager.sol";
import "./DAO.sol";

contract DAOManager is IDAOFactory {
    IFundManager public fundManager;
    IDKG public dkg;

    uint256 private requiredDeposit;
    address private admin;
    uint256 public daoCounter;
    uint256 public distributedKeyID;

    mapping(uint256 => address) public override daos;
    mapping(address => uint256) public deposits;

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "DAOManager::onlyAdmin: call must come from admin"
        );
        _;
    }

    // FIXME
    constructor(uint256 _requiredDeposit) {
        admin = msg.sender;
        requiredDeposit = _requiredDeposit;
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setFundManager(address _fundManager) external onlyAdmin {
        fundManager = IFundManager(_fundManager);
    }

    function setDKG(address _dkg) external onlyAdmin {
        dkg = IDKG(_dkg);
    }

    function setDistributedKeyID(uint256 _distributedKeyID) external onlyAdmin {
        distributedKeyID = _distributedKeyID;
    }

    function createDAO(
        uint256 _expectedID,
        IDAO.Config calldata _config,
        bytes32 _descriptionHash
    ) external payable override returns (uint256 daoIndex) {
        require(
            _expectedID == daoCounter,
            "DAOManager::createDAO: update expectedID to latest value"
        );

        require(
            msg.value >= requiredDeposit,
            "DAOManager::createDAO: not enough deposit to create a DAO"
        );

        require(
            daos[daoCounter] == address(0),
            "DAOManager::createDAO: DAO existed"
        );
        require(
            dkg.getDistributedKeyState(distributedKeyID) ==
                IDKG.DistributedKeyState.ACTIVE &&
                dkg.getType(distributedKeyID) == IDKG.DistributedKeyType.VOTING
        );
        address newDAO = address(
            new DAO(
                _config,
                address(fundManager),
                address(dkg),
                distributedKeyID,
                _descriptionHash
            )
        );

        daoIndex = daoCounter;
        daos[daoIndex] = newDAO;
        ++daoCounter;

        deposits[newDAO] = msg.value;

        _applyForFunding(newDAO);

        emit DAOCreated(daoIndex, newDAO, msg.sender, _descriptionHash);
    }

    function applyForFunding() external {
        require(
            deposits[msg.sender] >= requiredDeposit,
            "DAOManager::applyForFunding: not enough deposit to apply for next funding rounds"
        );
        fundManager.applyForFunding(msg.sender);
    }

    function _applyForFunding(address _dao) internal {
        fundManager.applyForFunding(_dao);
    }

    function applyForFundingDev(address _dao) external {
        _applyForFunding(_dao);
    }
}
