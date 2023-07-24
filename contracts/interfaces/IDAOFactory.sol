import "./IDAO.sol";

interface IDAOFactory {
    event DAOCreated(
        uint256 daoID,
        address indexed daoAddr,
        address creator,
        bytes32 indexed descriptionHash
    );

    function createDAO(
        uint256 _expectedID,
        IDAO.Config calldata _config,
        bytes32 _descriptionHash
    ) external payable returns (uint256 _daoID);

    function daos(uint256 daoID) external returns (address _addr);
}
