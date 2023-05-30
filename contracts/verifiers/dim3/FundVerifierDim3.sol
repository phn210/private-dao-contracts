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

contract FundingVerifierDim3 is IVerifier {
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
                6281520841133121361422102746902110249508204323167443567607314840374833905943,
                20816783850668869158435318627536067898889625730398300101978827335616104491828
            ],
            [
                14355766878598188855489278645878200503779184786533658192728886668101594779713,
                17527408840928211477152115541061579144037642597006230320712729402626637096633
            ]
        );
        vk.IC = new Pairing.G1Point[](20);

        vk.IC[0] = Pairing.G1Point(
            5875587686310264623971175967111646343763634784912570407002768482078939266302,
            18099352894618148264161953526068533051350473976980911514324142910055556402231
        );

        vk.IC[1] = Pairing.G1Point(
            7535994502585178013889771493012184751561759321832810238953125305259352016429,
            18576228774733200224949918240115479266302401088617021755842953878578471234990
        );

        vk.IC[2] = Pairing.G1Point(
            9620255719198009875536964034677887726794825396142364226711796693816589225636,
            3152441804887577991306510600339819074349785013952737406281858534387422349783
        );

        vk.IC[3] = Pairing.G1Point(
            20728069591891343950257811410562654351926233034664537897288698229718935891730,
            4664607374579586954497668675183931413211632319140526407511306138659823646438
        );

        vk.IC[4] = Pairing.G1Point(
            20096037127185544765523184788377972515233924380250073883618261239912573117032,
            8969183125803521858122729341405177355490038140531644050639406238521174745253
        );

        vk.IC[5] = Pairing.G1Point(
            15976522677457945549740327248586066716727581942887836591435777972465282871849,
            1715239967398110316354507025462791819954448124519844269947530662041694594998
        );

        vk.IC[6] = Pairing.G1Point(
            15494276408045927976342570371393606494073435880887410002357875241262646061452,
            7179214526353634304116690005174995666764716830785674405354362188280974485637
        );

        vk.IC[7] = Pairing.G1Point(
            12070162188001260241179071478575395665784815246103000120833049577012593861060,
            4181088724607393413910447740216945896864843230996428692403680117748870181593
        );

        vk.IC[8] = Pairing.G1Point(
            15765709349251359975592212311708667274766390125992686006125410166337097463616,
            19568102622395297447946985455240845033047673234065937923678919627342880347508
        );

        vk.IC[9] = Pairing.G1Point(
            6329801475580628634398121691475753575706847291929602238808870196011050172387,
            15892951789639565466986643496975241008408543100844560516836032826922231742156
        );

        vk.IC[10] = Pairing.G1Point(
            13596995614495079705166796846776416595327261602787677974476152884208975312410,
            20401054906683309714762091632770401499350775574916990209175036253624762770962
        );

        vk.IC[11] = Pairing.G1Point(
            18161031499833913799405205500143942235148115936778288646698236690002647799129,
            9507864726108021099871945477947909542145102226346605649275144067008666665593
        );

        vk.IC[12] = Pairing.G1Point(
            4324929827291596215827970874316046717223367590364698431012508385560206210994,
            1174763910726984080391581897596774386555418789606932443385074319084175168073
        );

        vk.IC[13] = Pairing.G1Point(
            8528774702432257546284588972783934688048913525024321283961939012157817563053,
            20178478767229223297171237634655479007989221452580472518663764551252768011992
        );

        vk.IC[14] = Pairing.G1Point(
            12595487467075763960759364069101055740211995173466003869506992014301586481134,
            1357142402058022745115432127174386836793591933410515200898155086868861233052
        );

        vk.IC[15] = Pairing.G1Point(
            11248104861390720243001810680095853546134807881521252465703859139369941624360,
            17562776865502556153910208065062829720531423714229322121591681437365516242844
        );

        vk.IC[16] = Pairing.G1Point(
            16565536407170194515744784237445166690818308052456281910958872867138676080468,
            16715659546218456803486846542069846108220006140212567164996412848752723055917
        );

        vk.IC[17] = Pairing.G1Point(
            13911994651622946429148181803113602102180785231338369303819555744182696708758,
            524259591069744586923608167967741053998686316676662065298429611851877743337
        );

        vk.IC[18] = Pairing.G1Point(
            10471044418721015683693349892786126238309661642515468465197959714706586730237,
            10838879008876283786695460087790163804790828904430893151461711517928008216853
        );

        vk.IC[19] = Pairing.G1Point(
            11528952200972493726853543560042561140467306671009152875441939863684838479516,
            1461927163784093972887814796554606300674574962037575531244958873803185081359
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
        return 19;
    }
}
