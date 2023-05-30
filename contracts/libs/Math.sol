// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CurveBabyJubJub.sol";

library Math {
    uint256 constant PRIME_Q =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function computeLagrangeCoefficient(
        uint8[] memory _listIndex,
        uint8 _threshold
    ) internal pure returns (uint256[] memory) {
        // require(_listIndex.length == threshold, "DKG contract: invalid input");
        uint256[] memory lagrangeCoefficient = new uint256[](_threshold);
        for (uint8 indexI; indexI < _threshold; indexI++) {
            // uint8 i = _listIndex[indexI];
            uint8 i = _listIndex[indexI];
            uint256 numerator = 1;
            uint256 denominator = 1;
            uint8 negativeCounter = 0;
            for (uint8 indexJ; indexJ < _threshold; indexJ++) {
                uint8 j = _listIndex[indexJ];
                if (i != j) {
                    numerator = numerator * j;
                    if (j < i) {
                        negativeCounter += 1;
                        denominator = denominator * (i - j);
                    } else {
                        denominator = denominator * (j - i);
                    }
                }
            }

            if (negativeCounter % 2 == 1) {
                denominator = CurveBabyJubJub.JUB_SUBORDER - denominator;
            }

            denominator = inverse(denominator);

            lagrangeCoefficient[indexI] = mulmod(
                numerator,
                denominator,
                CurveBabyJubJub.JUB_SUBORDER
            );
        }

        return lagrangeCoefficient;
    }

    function inverse(uint256 val) internal pure returns (uint256 invVal) {
        uint256 t = 0;
        uint256 newT = 1;
        uint256 r = CurveBabyJubJub.JUB_SUBORDER;
        uint256 newR = val;
        uint256 q;
        while (newR != 0) {
            q = r / newR;

            (t, newT) = (
                newT,
                addmod(
                    t,
                    (CurveBabyJubJub.JUB_SUBORDER -
                        mulmod(q, newT, CurveBabyJubJub.JUB_SUBORDER)),
                    CurveBabyJubJub.JUB_SUBORDER
                )
            );
            (r, newR) = (newR, r - q * newR);
        }

        return t;
    }
}
