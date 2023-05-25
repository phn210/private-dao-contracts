// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDKGRequest {
    struct Request {
        uint256 distributedKeyID;
        uint256[][] R;
        uint256[][] M;
        uint256[] result;
    }

    /*====================== MODIFIER ======================*/

    modifier onlyDKG() virtual;

    /*================== EXTERNAL FUNCTION ==================*/

    function submitTallyingResult(
        bytes32 _proposalID,
        uint256[] calldata _result
    ) external;

    /*==================== VIEW FUNCTION ====================*/
    function getProposalID(
        address _dao,
        uint256 _distributedKeyID,
        uint256 _timestamp
    ) external pure returns (bytes32);

    function getRequest(
        bytes32 _proposalID
    ) external view returns (Request memory);

    function getDistributedKeyID(
        bytes32 _proposalID
    ) external view returns (uint256);

    function getR(
        bytes32 _proposalID
    ) external view returns (uint256[][] memory);

    function getM(
        bytes32 _proposalID
    ) external view returns (uint256[][] memory);
}
