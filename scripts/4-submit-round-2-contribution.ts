import { expect } from "chai";
import { ethers, network } from "hardhat";
// @ts-ignore
import * as snarkjs from "snarkjs";
import { loadAllContracts } from "./constants/address";
import { CommitteeData } from "../test/data";
import { Committee } from "../libs/index";
import { Utils } from "../libs/utils";

var t = 3;
var n = 5;
// committeeIndex from 1 to n
var committeeIndex = 1;
var keyID = 0;

async function main() {
    let chainID = String(network.config.chainId);
    let accounts = await ethers.getSigners();
    let committee = accounts[committeeIndex];
    let contracts = await loadAllContracts(committee, chainID);

    let committeeData = CommitteeData.data1[committeeIndex - 1];
    console.log("Committee data: ", Utils.stringifyCircuitInput(committeeData));
    let listCommitteeIndex = [];
    for (let i = 1; i <= n; i++) {
        if (i != committeeIndex) {
            listCommitteeIndex.push(i);
        }
    }
    let round1DataSubmissions =
        await contracts.dkgContract.getRound1DataSubmissions(keyID);
    let recipientIndexes = [];
    let recipientPublicKeys = [];
    let f = [];
    for (let i = 0; i < round1DataSubmissions.length; i++) {
        let round1DataSubmission = round1DataSubmissions[i];
        let recipientIndex = round1DataSubmission.senderIndex;
        if (recipientIndex != committeeIndex) {
            recipientIndexes.push(recipientIndex);
            let recipientPublicKeyX = BigInt(round1DataSubmission.x[0]);
            let recipientPublicKeyY = BigInt(round1DataSubmission.y[0]);
            recipientPublicKeys.push([
                recipientPublicKeyX,
                recipientPublicKeyY,
            ]);
            // @ts-ignore
            f.push(BigInt(committeeData.f[recipientIndex]));
        }
    }
    let round2Contribution = Committee.getRound2Contributions(
        recipientIndexes,
        recipientPublicKeys,
        f,
        committeeData.C
    );
    let ciphers = round2Contribution.ciphers;
    let { proof, publicSignals } = await snarkjs.groth16.fullProve(
        round2Contribution.circuitInput,
        __dirname + "/../zk-resources/wasm/round-2-contribution.wasm",
        __dirname + "/../zk-resources/zkey/round-2-contribution_final.zkey"
    );
    proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
    await contracts.dkgContract.submitRound2Contribution(keyID, [
        committeeIndex,
        recipientIndexes,
        ciphers,
        proof,
    ]);
}

main().then(() => {
    console.log("DONE");
});
