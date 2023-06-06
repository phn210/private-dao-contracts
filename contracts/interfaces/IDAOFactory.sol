import './IDAO.sol';

interface IDAOFactory {
    event DAOCreated(uint256 daoId, address addr);

    function createDAO(IDAO.Config calldata config) external payable returns(uint256 daoId);
    function daos(uint256 daoId) external returns (address addr);
}