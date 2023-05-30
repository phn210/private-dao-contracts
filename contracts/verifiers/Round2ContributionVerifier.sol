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
import "../libs/Pairing.sol";
import "../interfaces/IVerifier.sol";

contract Round2ContributionVerifier is IVerifier {
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
                5974477545650231042023241844993761081863073923368386309746312801361815892477,
                21485337646393200745849263988681379073203593659965000858733150984083038502703
            ],
            [
                13993889929857028969109796769525830628245578318282192327757685934728974930550,
                20567502190823260220054267693000301698361752175599016650952621019290760108360
            ]
        );
        vk.IC = new Pairing.G1Point[](13);

        vk.IC[0] = Pairing.G1Point(
            12273165349952802938710806357599956247640805666905777679714819094967739443568,
            3482638084124723124700708867526946842467141637186948857070767438642279073322
        );

        vk.IC[1] = Pairing.G1Point(
            7398712724064053143392770525213410239543426683092096903575135263083277584621,
            8702533950231630014787759903158177627126133709810287535841613975484585252337
        );

        vk.IC[2] = Pairing.G1Point(
            6490741829313352939861097831237482027436842531868217780100513546878968067360,
            20702414071735257418799210660221517690333012959917700631138213718494475938753
        );

        vk.IC[3] = Pairing.G1Point(
            20880231230049517947797159858214348281917999552255363073549170836523000078081,
            5260007039257636600592154627659136341692730473118080925956020899517323875630
        );

        vk.IC[4] = Pairing.G1Point(
            11633607769646779752895886403371626173367015642952746882182647650434709663681,
            4322414378073876305993234106400604875515136047401165134206366176165693902417
        );

        vk.IC[5] = Pairing.G1Point(
            5419658044734948753637766190009363682523091792499084793051108144548307681116,
            16004770943436106976165441701905027016446794734987744627946716025217520058912
        );

        vk.IC[6] = Pairing.G1Point(
            405020968995685540316403283329232787881514782216901334186192596945416548963,
            4224051344362555273404810268559168281388729122125631506133667341874785430360
        );

        vk.IC[7] = Pairing.G1Point(
            18531671936000091574882313382872525706406289639898035956871775273605477319776,
            13399799027030111290563956428744993780197071158326370689271015519841697434086
        );

        vk.IC[8] = Pairing.G1Point(
            19334169506442103494763825944951821847332840283173827211525882089578274754427,
            13656986564271254011457885239831691190206337201085935851890946921941528435698
        );

        vk.IC[9] = Pairing.G1Point(
            328277833092031233357031393538196246169941894938339673222564615065700921429,
            14649418578788395274275859867580195868541137394854660593969183578256231082705
        );

        vk.IC[10] = Pairing.G1Point(
            15064094640341089465012414898804491449937991235059184573457421308302549870044,
            8695453262658378635540490684957355957025867061920194743090617632842689313759
        );

        vk.IC[11] = Pairing.G1Point(
            5223651670202287392177920359234725493600835925356778252526557320532232050521,
            14161416719204456376492359316751897291821465388584118994592107511467120980522
        );

        vk.IC[12] = Pairing.G1Point(
            7896030286206658972404226595318157973769327088259809262225587540785313168044,
            2066647944552678978617610339402766304780639460132660300887613125081725726542
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
        return 12;
    }
}
