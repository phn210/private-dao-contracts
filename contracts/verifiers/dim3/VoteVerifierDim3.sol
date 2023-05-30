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
                8028391451146179729909940362149584325188040503454495593547364033068207015585,
                862057394348381576898919584288514348045610259146320335325480548211200822614
            ],
            [
                1447297135138070509755860588106820845243319383077904653460218518524837701500,
                5348019819121322538028965902919728306960365984764457472233924250538046393581
            ]
        );
        vk.IC = new Pairing.G1Point[](19);

        vk.IC[0] = Pairing.G1Point(
            7060786117991965548029832090029643339251635096548441940740605761583086767079,
            6378427325785050510563246128579623067411820587765826388905292760487876334618
        );

        vk.IC[1] = Pairing.G1Point(
            20682168828420451133066110234837729506897988666486686688496077918942751086019,
            20228223821590361378293903469544874090979424715939493945598320022821038036272
        );

        vk.IC[2] = Pairing.G1Point(
            16661071474951412674835062057113874427252552725504765974647418323236899056125,
            20054796138453573730904343727644470819803949027953146137549637683153931040246
        );

        vk.IC[3] = Pairing.G1Point(
            15353124845273449448760314469050516889193754450966474635252594485663931917023,
            14788244961515020735219415345376685194638972589026453200441495417774934214593
        );

        vk.IC[4] = Pairing.G1Point(
            1387141123372482363733832261345340084973808950696830880563021910115028781474,
            2663284858511362881643701253598648208533606604126535051277299099154213567224
        );

        vk.IC[5] = Pairing.G1Point(
            15044657213634096856998290572148632908795237218767007288726627545448421604323,
            5995090715391004205275223590324612614910067053051760683993178404349693127685
        );

        vk.IC[6] = Pairing.G1Point(
            2256714437850909708607612453334412476060168339428668519384888726054534376700,
            18738036679741549172241754073609404816835248676328791710346812268124528095619
        );

        vk.IC[7] = Pairing.G1Point(
            17042065768866807708992521129781233973525719186987240300944234991714104868318,
            9460060386769964100439751426814050284710942141103633864172562332783990849601
        );

        vk.IC[8] = Pairing.G1Point(
            11335924207038290484025551306922634579836521350946920629849073302648682017976,
            5238169038608860758527933150663831968967665909498676769849082973550550071121
        );

        vk.IC[9] = Pairing.G1Point(
            12043151925216539939480339297828987006119091304086662828533856167169358964777,
            2517675595964892274861057421867981790439086726967130186104987353712134470260
        );

        vk.IC[10] = Pairing.G1Point(
            2263981355198374123201895334917223914784742843945313858632971092591705888553,
            4784194596916517840301336078313753122037577558051595623235775037521570398039
        );

        vk.IC[11] = Pairing.G1Point(
            5706428150059634160201514085452547164953436644884994825319879386194095289456,
            14596929217572853240214712760770194652201714926534147549201128092327093950726
        );

        vk.IC[12] = Pairing.G1Point(
            16643677490402636511331090834238023380823395728993915305816849462408174002508,
            16874419734787591583998247349392666965555950930400179291063029788831607322236
        );

        vk.IC[13] = Pairing.G1Point(
            13808776572060706951433372305188814193874682134085333773883349750837102783219,
            17474171788804986762437422771605901234416479160261562754110629877715663184135
        );

        vk.IC[14] = Pairing.G1Point(
            20455268128311741074040156711072449037601800936682095531932569303196494411049,
            1368647594986560437211240361093306418457598636679452895510488555025281122041
        );

        vk.IC[15] = Pairing.G1Point(
            1343536039947239129302941582129239328135212866134732914920684611856278112802,
            8247389762853022065016840458648741301634644396434809371236142739771652367393
        );

        vk.IC[16] = Pairing.G1Point(
            11505361459162394581347189807464653571046154857541543885370864778056075465057,
            19232797727747185779021466181242230006527485595508643449653594825546320360702
        );

        vk.IC[17] = Pairing.G1Point(
            17128628712659531006207296111485714519901519398454697917856702296477739514106,
            13320227525861952756430143863732600673687104416144145837909934657004828184914
        );

        vk.IC[18] = Pairing.G1Point(
            3351627206102934041264469974917077867722162121621868065513417899582829815767,
            20304984200619569155040673474007339663890696351492839075939284525595270939187
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
