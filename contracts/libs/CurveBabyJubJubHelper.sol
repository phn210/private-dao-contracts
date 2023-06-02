// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CurveBabyJubJub.sol";

contract CurveBabyJubJubHelper {
    uint256 public constant A = 0x292FC;
    // D = 168696
    uint256 public constant D = 0x292F8;
    // Prime Q = 21888242871839275222246405745257275088548364400416034343698204186575808495617
    uint256 public constant Q =
        0x30644E72E131A029B85045B68181585D2833E84879B9709143E1F593F0000001;
    uint256 public constant JUB_SUBORDER =
        2736030358979909402780800718157159386076813972158567259200215660948447373041;
    uint256 public constant BASE_X =
        5299619240641551281634865583518297030282874472190772894086521144482721001553;
    uint256 public constant BASE_Y =
        16950150798460657717958625567821834550301663161624707787222815936182638968203;

    function pointAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2
    ) public view returns (uint256 x3, uint256 y3) {
        (x3, y3) = CurveBabyJubJub.pointAdd(_x1, _y1, _x2, _y2);
    }

    function pointMul(
        uint256 _x1,
        uint256 _y1,
        uint256 _d
    ) public view returns (uint256 x2, uint256 y2) {
        (x2, y2) = CurveBabyJubJub.pointMul(_x1, _y1, _d);
    }

    function pointDouble(
        uint256 _x1,
        uint256 _y1
    ) public view returns (uint256 x2, uint256 y2) {
        (x2, y2) = CurveBabyJubJub.pointDouble(_x1, _y1);
    }

    function isOnCurve(uint256 _x, uint256 _y) public pure returns (bool) {
        return CurveBabyJubJub.isOnCurve(_x, _y);
    }
}
