import './IDAO.sol';

interface IDAOFactory {
    event DAOCreated(uint256 daoId, address daoAddr, address creator, bytes32 description);

    function createDAO(uint256 expectedId, IDAO.Config calldata config, bytes32 descriptionHash) external payable returns(uint256 daoId);
    function daos(uint256 daoId) external returns (address addr);
}