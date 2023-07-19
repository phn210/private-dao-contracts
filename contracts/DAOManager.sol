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
    uint256 public distributedKeyId;

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

    function setDistributedKeyId(uint256 _distributedKeyId) external onlyAdmin {
        distributedKeyId = _distributedKeyId;
    }

    function createDAO(
        uint256 expectedId,
        IDAO.Config calldata config,
        bytes32 descriptionHash
    ) external payable override returns (uint256 daoId) {
        require(
            expectedId == daoCounter,
            "DAOManager::createDAO: update expectedId to latest value"
        );

        require(
            msg.value >= requiredDeposit,
            "DAOManager::createDAO: not enough deposit to create a DAO"
        );

        require(
            daos[daoCounter] == address(0),
            "DAOManager::createDAO: DAO existed"
        );

        address newDAO = address(
            new DAO(
                config,
                address(fundManager),
                address(dkg),
                distributedKeyId,
                descriptionHash
            )
        );

        daoId = daoCounter;
        daos[daoId] = newDAO;
        ++daoCounter;

        deposits[newDAO] = msg.value;

        _applyForFunding(newDAO);

        emit DAOCreated(daoId, newDAO, msg.sender, descriptionHash);
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
