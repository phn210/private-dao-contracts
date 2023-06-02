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
var fundingRoundID = 0;
var keyID = 0;

async function main() {
    let chainID = String(network.config.chainId);
    let accounts = await ethers.getSigners();
    let committee = accounts[committeeIndex];
    let contracts = await loadAllContracts(committee, chainID);

    let committeeData;
    committeeData = CommitteeData.data1[committeeIndex - 1];
    console.log("Committee data: ", Utils.logFullObject(committeeData));
    let fundingRound = await contracts.fundManager.fundingRounds(
        fundingRoundID
    );
    let requestID = fundingRound.requestID;
    console.log(
        "TallyTracker state:",
        await contracts.dkgContract.getTallyTrackerState(requestID)
    );
    console.log(
        "Can only submit tally contribution if tally tracker is in CONTRIBUTION state"
    );
    let tmp = await contracts.dkgContract.getR(requestID);
    let R = [];
    for (let i = 0; i < tmp.length; i++) {
        R.push([BigInt(tmp[i][0]), BigInt(tmp[i][1])]);
    }

    let round2DataSubmissions =
        await contracts.dkgContract.getRound2DataSubmissions(
            keyID,
            committeeIndex
        );
    let senderIndexes = [];
    let u = [];
    let c = [];
    for (let i = 0; i < n; i++) {
        senderIndexes.push(round2DataSubmissions[i].senderIndex);
        u.push([
            BigInt(round2DataSubmissions[i].ciphers[0]),
            BigInt(round2DataSubmissions[i].ciphers[1]),
        ]);
        c.push(BigInt(round2DataSubmissions[i].ciphers[2]));
    }
    let tallyContribution = Committee.getTallyContribution(
        committeeData.a0,
        committeeData.secret["f(i)"],
        u,
        c,
        R
    );
    let { proof, publicSignals } = await snarkjs.groth16.fullProve(
        tallyContribution.circuitInput,
        __dirname + "/../zk-resources/wasm/tally-contribution_dim3.wasm",
        __dirname + "/../zk-resources/zkey/tally-contribution_dim3_final.zkey"
    );
    proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
    await contracts.dkgContract.submitTallyContribution(requestID, [
        committeeIndex,
        tallyContribution.D,
        proof,
    ]);
}

main().then(() => {
    console.log("DONE");
});
