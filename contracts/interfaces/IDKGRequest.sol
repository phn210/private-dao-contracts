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
        bytes32 _requestID,
        uint256[] calldata _result
    ) external;

    /*==================== VIEW FUNCTION ====================*/
    
    function getRequestID(
        uint256 _distributedKeyID,
        address _requestor,
        uint256 _nonce
    ) external pure returns (bytes32);

    function getRequest(
        bytes32 _requestID
    ) external view returns (Request memory);

    function getDistributedKeyID(
        bytes32 _requestID
    ) external view returns (uint256);

    function getR(
        bytes32 _requestID
    ) external view returns (uint256[][] memory);

    function getM(
        bytes32 _requestID
    ) external view returns (uint256[][] memory);
}
