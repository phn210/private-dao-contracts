// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../1-deploy-with-check";
import { CommitteeData } from "../../test/data";
import { Committee } from "../../libs/index";
import { Utils } from "../../libs/utils";
import { getFundedValue } from "../constants/funded";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const fundingRoundID = 0;
    const dim = 3;

    console.log(
        `Funding Round ${fundingRoundID} State:`,
        await _.FundManager.getFundingRoundState(fundingRoundID)
    );

    let fundingRound = await _.FundManager.fundingRounds(
        fundingRoundID
    );
    let requestID = fundingRound.requestID;
    console.log(
        "TallyTracker state:",
        await _.DKG.getTallyTrackerState(requestID)
    );
    
    let tallyDataSubmissions =
        await _.DKG.getTallyDataSubmissions(requestID);
    let tmp = await _.DKG.getM(requestID);
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
    let result = [20000000000000000n, 20000000000000000n, 10000000000000000n];
    // if (false) {
    //     for(let i = 0; i < $.voters.length; i++) {
    //         const funded = getFundedValue(_.FundManager.address.toLowerCase(), $.voters[i].address.toLowerCase())
    //         result.map(dim => {

    //         })
    //     }
    // }
    let { proof, publicSignals } = await snarkjs.groth16.fullProve(
        { listIndex: listIndex, D: D, M: M, result: result },
        path.join(path.resolve(), '/zk-resources/wasm/result-verifier_dim3.wasm'),
        path.join(path.resolve(), '/zk-resources/zkey/result-verifier_dim3_final.zkey')
    );
    proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
    await _.DKG.submitTallyResult(requestID, result, proof);
    console.log('Funding round result is submitted');
    
    console.log(
        `Funding Round ${fundingRoundID} State:`,
        await _.FundManager.getFundingRoundState(fundingRoundID)
    );

    await _.FundManager.finalizeFundingRound(fundingRoundID);
    console.log('Funding round is finalized');
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
