pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract PoseidonUnit2 {
    function poseidon(uint256[] calldata input) public pure returns (uint256) {}
}

contract Poseidon {
    PoseidonUnit2 public poseidon2;

    constructor(address _poseidon2) {
        poseidon2 = PoseidonUnit2(_poseidon2);
    }

    function hash(uint256[2] calldata _input) external view returns (uint256) {
        uint256[] memory input = new uint256[](2);
        input[0] = _input[0];
        input[1] = _input[1];
        return poseidon2.poseidon(input);
    }
}
