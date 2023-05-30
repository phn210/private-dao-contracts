// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVerifier {
    function getPublicInputsLength() external pure returns (uint256);

    function verifyProof(
        uint[2] memory _a,
        uint[2][2] memory _b,
        uint[2] memory _c,
        uint[] memory _publicInputs
    ) external view returns (bool r);
}
