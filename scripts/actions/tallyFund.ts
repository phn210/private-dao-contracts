// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../1-deploy-with-check";
import { CommitteeData } from "../../test/data";
import { Committee } from "../../libs/index";
import { Utils } from "../../libs/utils";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const committeeIndexes = [1, 2, 3];
    const fundingRoundID = 8;
    const keyID = 10;

    console.log(
        `Funding Round ${fundingRoundID} State:`,
        await _.FundManager.getFundingRoundState(fundingRoundID)
    );

    await _.FundManager.startTallying(fundingRoundID);
    console.log('Funding round is tallying');
    
    // for (let i = 0; i < committeeIndexes.length; i++) {
    //     let committeeIndex = committeeIndexes[i];
    //     let committee = $.committee[committeeIndex-1];        

    //     let committeeData;
    //     committeeData = CommitteeData.data1[committeeIndex - 1];

    //     let fundingRound = await _.FundManager.fundingRounds(
    //         fundingRoundID
    //     );
    //     let requestID = fundingRound.requestID;
    //     console.log(requestID);
    //     console.log(
    //         "TallyTracker state:",
    //         await _.DKG.getTallyTrackerState(requestID)
    //     );

    //     let tmp = await _.DKG.getR(requestID);
    //     console.log(tmp);
    //     let R = [];
    //     for (let i = 0; i < tmp.length; i++) {
    //         R.push([BigInt(tmp[i][0]), BigInt(tmp[i][1])]);
    //     }

    //     let round2DataSubmissions =
    //         await _.DKG.getRound2DataSubmissions(
    //             keyID,
    //             committeeIndex
    //         );
        
    //     let senderIndexes = [];
    //     let u = [];
    //     let c = [];
    //     for (let i = 0; i < n-1; i++) {
    //         senderIndexes.push(round2DataSubmissions[i][0]);
    //         u.push([
    //             BigInt(round2DataSubmissions[i].ciphers[0]),
    //             BigInt(round2DataSubmissions[i].ciphers[1]),
    //         ]);
    //         c.push(BigInt(round2DataSubmissions[i].ciphers[2]));
    //     }
    //     let tallyContribution = Committee.getTallyContribution(
    //         committeeData.a0,
    //         committeeData.secret["f(i)"],
    //         u,
    //         c,
    //         R
    //     );
    //     console.log(Utils.logFullObject(tallyContribution.circuitInput))
    //     let { proof, publicSignals } = await snarkjs.groth16.fullProve(
    //         tallyContribution.circuitInput,
    //         path.join(path.resolve(), '/zk-resources/wasm/tally-contribution_dim3.wasm'),
    //         path.join(path.resolve(), '/zk-resources/zkey/tally-contribution_dim3_final.zkey')
    //     );
    //     proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
    //     await _.DKG.connect(committee).submitTallyContribution(requestID, [
    //         committeeIndex,
    //         tallyContribution.D,
    //         proof,
    //     ]);
    //     console.log(`Committee member ${i} contributed to tally process`);
    // }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
