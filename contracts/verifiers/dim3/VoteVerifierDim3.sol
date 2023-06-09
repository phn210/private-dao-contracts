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
                15310599923222752481351540941258740488598586592985122700373040976573180460718,
                18240942370865788586339081948450218965463714502149315470642323071371384367077
            ],
            [
                12684593623473665563142838572340466539456748891283370294206126560578320293954,
                7835176973155782990117247626803187293610341853658476419130709709744919398921
            ]
        );
        vk.IC = new Pairing.G1Point[](19);

        vk.IC[0] = Pairing.G1Point(
            13182011370679417948790097297063483423258361354712190573126556096991081771613,
            20980841949223445407205786025005676109896459318342316743277913968301631479580
        );

        vk.IC[1] = Pairing.G1Point(
            21707947536129298059001585284519188831044383078379020841115298151905715129332,
            7343816555122574025881813755397319016079928311869419942352593938683420960632
        );

        vk.IC[2] = Pairing.G1Point(
            858617070625289736295342692214030515694773791948621214634114248209609943009,
            7922420932497255597195559696206103376158913603854250487262696873377218928074
        );

        vk.IC[3] = Pairing.G1Point(
            2835919026887223956192497250315064227407025073478199012868485711580118685165,
            12180084250630251127457094148108140032947147504198492129001798452602137643099
        );

        vk.IC[4] = Pairing.G1Point(
            3893550589257350602002910730358251012587002030494030330566796301164204510579,
            8743343800143483282535157897467968593662432641332635195130340920314187854917
        );

        vk.IC[5] = Pairing.G1Point(
            3615497506454644844551086829845344437502504195625841052399069516962699281542,
            9667024111087888369771545227604087794864125342404990311960939763131314491082
        );

        vk.IC[6] = Pairing.G1Point(
            10555438785948996465342754073212786964453189998514136757176546516072325243713,
            15107188314666360908389348119532231646462450100305223816140087094633755647782
        );

        vk.IC[7] = Pairing.G1Point(
            15797313579011279161072880591456233490195890559591297003528415596447393921816,
            7733471695666266736220016817339783219113175325597865200822432173445220231710
        );

        vk.IC[8] = Pairing.G1Point(
            5411139507656217799119469236001505394762149115816406272650815529485419309669,
            12190124190987141861069874513080228731016658563140442580618242220563151100163
        );

        vk.IC[9] = Pairing.G1Point(
            2322300239209230985761653112677726018278306986331447527007174933369220244289,
            2917655929489675781772754157886621900918529619853977239260857163158362984822
        );

        vk.IC[10] = Pairing.G1Point(
            11148644632218739963192931454769109304358459972920876496923571171510451296888,
            12593320500109608574059690691025947637800019047514431757375515706297529516047
        );

        vk.IC[11] = Pairing.G1Point(
            1047348199721956393656558119582255468176671797493046764868602605641255595158,
            12250558403607737025450871041955302306269850472901038055366032963048342043771
        );

        vk.IC[12] = Pairing.G1Point(
            16605298901292593858348862258689605230390411487559901292554091116764262386140,
            12578932786020141398576555194720120496273494588778365785381666216946365428982
        );

        vk.IC[13] = Pairing.G1Point(
            3134037987799257667415429940469718379570626577789619020751338026275481672516,
            9713879159194245399577427847126793816999960552346419657916913968728632699007
        );

        vk.IC[14] = Pairing.G1Point(
            12861417679662635514508814160510983456949150673740321660360084066452395495158,
            12914188924696851656612016064642111925237861918817463170718045965351319405111
        );

        vk.IC[15] = Pairing.G1Point(
            9948460903211663650397963330055525258864282905999381027544521647202624443688,
            1981193413913870045596881361321378713854071400273757874027585025440023603066
        );

        vk.IC[16] = Pairing.G1Point(
            12490506083960984909325273334197207482852742426380985153532554949041741110237,
            12146429367157346352682267474203808383307791688712529798532021003464094223441
        );

        vk.IC[17] = Pairing.G1Point(
            9288469248513584049547739419801268380338958522223093765316006831124838647006,
            6349219171399330061759829786013602671441377091130032522745094867041919815367
        );

        vk.IC[18] = Pairing.G1Point(
            3599672233323696299257843419336229683283066331059910829903250469850746395811,
            4687229251493684362125064900337489111835432571741068518013223374875422706490
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
