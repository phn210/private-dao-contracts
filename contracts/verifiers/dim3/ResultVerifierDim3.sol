//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "../../libs/Pairing.sol";
import "../../interfaces/IVerifier.sol";

contract ResultVerifierDim3 is IVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [
                4252822878758300859123897981450591353533073413197771768651442665752259397132,
                6375614351688725206403948262868962793625744043794305715222011528459656738731
            ],
            [
                21847035105528745403288232691147584728191162732299865338377159692350059136679,
                10505242626370262277552901082094356697409835680220590971873171140371331206856
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                17176120599915757243258598902984131738539583024438649177416720516099761615478,
                2641640179723689435053164607409983658470311822553727046282573849971620629903
            ],
            [
                1316285190276966596496195923702632168705632352260102809731368238435531731913,
                5070492753343317685205284096346247303309438228686993524604973113402988735539
            ]
        );
        vk.IC = new Pairing.G1Point[](10);

        vk.IC[0] = Pairing.G1Point(
            20506275725697502134510736817670937847341650026420030467297068506266094469722,
            9814017062708128935965019167339106583081128743740204705965129667274250101916
        );

        vk.IC[1] = Pairing.G1Point(
            11456143142388536482530458263122709286522176619129207230113541147586975312887,
            21037061787634211928311238709312867689246556834004844528606252019960628607565
        );

        vk.IC[2] = Pairing.G1Point(
            6573261439975817550232900254743163540431271198104271016086466749224360655665,
            16102959208552998641830731137619324000707504741087441551404647429606000406819
        );

        vk.IC[3] = Pairing.G1Point(
            10245530037307151286758955107573624746138177104693243196086052580765444876174,
            14233222811999346713569720713098373981145828209025902497036869324836952038516
        );

        vk.IC[4] = Pairing.G1Point(
            4374148675790246195738187134840117291990964695331860289589095618309768352244,
            16701497980526733046615633757080968634622529101870153408838595806802141376536
        );

        vk.IC[5] = Pairing.G1Point(
            16485721197484700331150559700397348510125859377701870238833018139664420034512,
            2445987057257197324098959681009037122374709709054055731271557559984935415997
        );

        vk.IC[6] = Pairing.G1Point(
            15657405036549674514299072093478019594290328223551492420882231607290344663909,
            16786796793851185697483368082275131490459002915186260831772935124180332026468
        );

        vk.IC[7] = Pairing.G1Point(
            9149654787492544965560410408292236301002981242170804815876162147590837810803,
            18622890812199582289353113429472794569347780338690788269209571105424233299418
        );

        vk.IC[8] = Pairing.G1Point(
            4182178009216339453470794719837574287281318160010532623856271648944793725666,
            15891617891035432957560548111437178477757133097901838160127996664938801424798
        );

        vk.IC[9] = Pairing.G1Point(
            11677613955799474504401676721251241856372752909131593115344842847160741774572,
            2272790715579732589324329280571450864972826528232462616114207395318894133332
        );
    }

    function verify(
        uint[] memory input,
        Proof memory proof
    ) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[] memory input
    ) public view override returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for (uint i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }

    function getPublicInputsLength() external pure override returns (uint256) {
        return 9;
    }
}
