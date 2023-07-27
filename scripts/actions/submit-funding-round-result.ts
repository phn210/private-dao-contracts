// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../deploy-with-check";
import { Committee, Utils } from "distributed-key-generation";
import { VoterData } from "../../test/mock-data";

const fundingRoundID = 0;
async function main() {
    const { _, $, t, n, config } = await deploy(false, false);

    console.log(
        `Funding Round ${fundingRoundID} State:`,
        await _.FundManager.getFundingRoundState(fundingRoundID)
    );
    let fundingRound = await _.FundManager.fundingRounds(fundingRoundID);
    console.log(fundingRound);
    let requestID = fundingRound.requestID;
    let keyID = await _.FundManager.getDistributedKeyID(requestID);
    console.log(`This funding round use distributed key ${keyID}`);
    console.log(
        "TallyTracker state:",
        await _.DKG.getTallyTrackerState(requestID)
    );

    let dim = Number((await _.DKG.distributedKeys(keyID)).dimension);
    let tallyDataSubmissions = await _.DKG.getTallyDataSubmissions(requestID);
    let listIndex = [];
    let D: any = [];
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
    let tmp = await _.DKG.getM(requestID);
    let M = [];
    for (let i = 0; i < dim; i++) {
        M.push([BigInt(tmp[i][0]), BigInt(tmp[i][1])]);
    }
    let resultVector = Committee.getResultVector(listIndex, D, M);
    // Should brute force resultVector to get result
    let result = [...Array(dim).keys()].map((index: any) => 0n);
    for (let i = 0; i < $.voters.length; i++) {
        let voterData = {
            votingPower: VoterData[0].votingPower[i],
            fundingVector: VoterData[0].fundingVector[i],
            votingVector: VoterData[0].votingVector[i],
        };

        for (let j = 0; j < dim; j++) {
            result[j] +=
                voterData.votingPower * BigInt(voterData.fundingVector[j]);
        }
    }
    console.log(`Result ${result} will be submitted`);

    let { proof, publicSignals } = await snarkjs.groth16.fullProve(
        { listIndex: listIndex, D: D, M: M, result: result },
        path.join(
            path.resolve(),
            "/zk-resources/wasm/result-verifier_dim3.wasm"
        ),
        path.join(
            path.resolve(),
            "/zk-resources/zkey/result-verifier_dim3_final.zkey"
        )
    );
    proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
    await _.DKG.submitTallyResult(requestID, result, proof);
    console.log("Funding round result is submitted");

    console.log(
        "TallyTracker state:",
        await _.DKG.getTallyTrackerState(requestID)
    );
    console.log(
        `Funding Round ${fundingRoundID} State:`,
        await _.FundManager.getFundingRoundState(fundingRoundID)
    );
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
