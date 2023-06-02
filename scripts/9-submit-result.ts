import { expect } from "chai";
import { ethers, network } from "hardhat";
// @ts-ignore
import * as snarkjs from "snarkjs";
import { loadAllContracts } from "./constants/address";
import { CommitteeData } from "../test/data";
import { Committee } from "../libs/index";
import { Utils } from "../libs/utils";

var dim = 3;
var t = 3;
var n = 5;
// committeeIndex from 1 to n
var committeeIndex = 1;
var fundingRoundID = 0;
var keyID = 0;

async function main() {
    let chainID = String(network.config.chainId);
    let accounts = await ethers.getSigners();
    let founder = accounts[0];
    let contracts = await loadAllContracts(founder, chainID);

    let fundingRound = await contracts.fundManager.fundingRounds(
        fundingRoundID
    );
    let requestID = fundingRound.requestID;
    console.log(
        "TallyTracker state:",
        await contracts.dkgContract.getTallyTrackerState(requestID)
    );
    console.log(
        "Can only submit result if tally tracker is in RESULT_AWAITING state"
    );
    console.log(
        "Can only submit result if funding round is still in TALLYING state"
    );

    let tallyDataSubmissions =
        await contracts.dkgContract.getTallyDataSubmissions(requestID);
    let tmp = await contracts.dkgContract.getM(requestID);
    let listIndex = [];
    let D: any = [];
    let M = [];

    for (let i = 0; i < tallyDataSubmissions.length; i++) {
        let tallyDataSubmission = tallyDataSubmissions[i];
        listIndex.push(Number(tallyDataSubmission.senderIndex));
        D[i] = [];
        for (let j = 0; j < dim; j++) {
            D[i].push([
                BigInt(tallyDataSubmission.Di[j][0]),
                BigInt(tallyDataSubmission.Di[j][1]),
            ]);
        }
    }

    for (let i = 0; i < dim; i++) {
        M.push([BigInt(tmp[i][0]), BigInt(tmp[i][1])]);
    }
    let resultVector = Committee.getResultVector(listIndex, D, M);

    // Should brute force resultVector to get result
    let result = [0n, 0n, 0n];
    let { proof, publicSignals } = await snarkjs.groth16.fullProve(
        { listIndex: listIndex, D: D, M: M, result: result },
        __dirname + "/../zk-resources/wasm/result-verifier_dim3.wasm",
        __dirname + "/../zk-resources/zkey/result-verifier_dim3_final.zkey"
    );
    proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
    await contracts.dkgContract.submitTallyResult(requestID, result, proof);

    console.log("After submit result, funding round state will be SUCCEEDED");
}

main().then(() => {
    console.log("DONE");
});
