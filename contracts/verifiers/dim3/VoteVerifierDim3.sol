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

contract VotingVerifierDim3 is IVerifier {
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
                4811939369465132942347972333273472240541321482407627734249484264093665846229,
                19534981616249473946701429470932400458113342168572653388074455316682114045612
            ],
            [
                4235332172795486933377806010319433186739082704327067385911494432430680212395,
                15909360001890847841902009903181474670316025466749290230813966339231095453388
            ]
        );
        vk.IC = new Pairing.G1Point[](19);

        vk.IC[0] = Pairing.G1Point(
            16502128350765674874687735768864839154773946678998810209368078493729256303112,
            10049860738624459122162816458670330926878733754302610040605815339430655216329
        );

        vk.IC[1] = Pairing.G1Point(
            15593130587532716084376330440382759146038132803185094931833399833756048410975,
            18682887344761489222672079931656855162419711184598709778579005776465430699076
        );

        vk.IC[2] = Pairing.G1Point(
            13434244399482318771710910789960742192502030818155588208752902476106824169891,
            9979617362079759211889725808113917214668136271384082256132432814003972176790
        );

        vk.IC[3] = Pairing.G1Point(
            12085334540325162460779971635014201548373284133886628046452993248250281173261,
            8149715389304854763719829063630684369351418148480639549864632898241531930223
        );

        vk.IC[4] = Pairing.G1Point(
            19333621434270114584271908785155471900609290339042779745994071483835449934075,
            15145325902489518605558381161656677829957519267618260657055990372772576875318
        );

        vk.IC[5] = Pairing.G1Point(
            10832828214594136448764619595342951786851998206796613641064135006979611765144,
            19377161910275431219725638220735746118856221792008137947203948040691170973888
        );

        vk.IC[6] = Pairing.G1Point(
            5914309931691658497859595623462775821629982702171729184222829967989310330488,
            2739320908787433592750176667148419244102804048469134237400481860714336994958
        );

        vk.IC[7] = Pairing.G1Point(
            1185924910937027768518658833335595653591890630030256158837696082093985608321,
            6270080669049182979840499700120894940010831674156867320274162681236488754410
        );

        vk.IC[8] = Pairing.G1Point(
            15400544007515593523124476782837944292959190944022640812973063619708296205959,
            3998747927151146725513749860142637017069120994457453797382556210279122717209
        );

        vk.IC[9] = Pairing.G1Point(
            6383486322885220191776167508697679534194212554720700808785746517206264006500,
            1120706647707954952156295104943454495772037771987730350642332919555323527584
        );

        vk.IC[10] = Pairing.G1Point(
            2927981836638353469930926670257129673281935702663626583597007787225614173020,
            12466412890727975589355958638626855442378836250603983097573536435706811122062
        );

        vk.IC[11] = Pairing.G1Point(
            7488223872681796386833242584481478889594943298780780998254128525498097656050,
            18613771933923343865520527523536964666000324101904970835534715264403016812272
        );

        vk.IC[12] = Pairing.G1Point(
            2609600707180209765032593800050550523489458429888549424581498887734423843038,
            11233324741747162326742883633253201794651043236490077617695122894120141729510
        );

        vk.IC[13] = Pairing.G1Point(
            534154550195408893217180664650035419205765094869758821700475601133888294418,
            9794199022712533650437912450166355623941777182361783144977941146052761569560
        );

        vk.IC[14] = Pairing.G1Point(
            1514330291483996417151218303737877465707244763808256840647116921843280021133,
            9416688438938931321038671567378628860250451264704601023495557772596087716362
        );

        vk.IC[15] = Pairing.G1Point(
            2270155829495359214414238933926507353637246478511580365254440795455796960380,
            5745898606972138126163688537747402752263551727275375763110113784235065973482
        );

        vk.IC[16] = Pairing.G1Point(
            13176402815073666367624341575375486033330081225549421588959279608080428442768,
            5362511717450101134467754511448190468153808152147114797575614598790746899435
        );

        vk.IC[17] = Pairing.G1Point(
            18539689066762607296540550234567187869853066634135109041918444170552816921377,
            4678526876428354289455851527263206161977724916850852942209563413287633350585
        );

        vk.IC[18] = Pairing.G1Point(
            17327124573622977406770709250460405267147105876933331734640209890351933709433,
            14504529709604984968694248425140024666839487898725772396165711259695725647529
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
        return 18;
    }
}
