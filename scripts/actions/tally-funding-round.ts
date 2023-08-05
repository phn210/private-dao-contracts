// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../deploy-with-check";
import { CommitteeData } from "../../test/mock-data";
import { Committee, Utils } from "distributed-key-generation";

const fundingRoundID = 0;
const committeeIndexes = [1, 2, 3];
async function main() {
    const { _, $, t, n, config } = await deploy(false, false);
    // await _.FundManager.startTallying(fundingRoundID);
    // console.log("Funding round is tallying");

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

    let tmp = await _.DKG.getR(requestID);
    let R = [];
    for (let i = 0; i < tmp.length; i++) {
        R.push([BigInt(tmp[i][0]), BigInt(tmp[i][1])]);
    }

    for (let i = 0; i < committeeIndexes.length; i++) {
        let committeeIndex = committeeIndexes[i];
        let committee = $.committee[committeeIndex - 1];
        let committeeData = CommitteeData[0][committeeIndex - 1];

        let round2DataSubmissions = await _.DKG.getRound2DataSubmissions(
            keyID,
            committeeIndex
        );
        let senderIndexes = [];
        let u = [];
        let c = [];
        for (let i = 0; i < n - 1; i++) {
            senderIndexes.push(round2DataSubmissions[i][0]);
            u.push([
                BigInt(round2DataSubmissions[i].ciphers[0]),
                BigInt(round2DataSubmissions[i].ciphers[1]),
            ]);
            c.push(BigInt(round2DataSubmissions[i].ciphers[2]));
        }

        let tallyContribution = Committee.getTallyContribution(
            committeeIndex,
            committeeData.C,
            committeeData.a0,
            (committeeData.f as any)[committeeIndex.toString()],
            u,
            c,
            R
        );
        let { proof, publicSignals } = await snarkjs.groth16.fullProve(
            tallyContribution.circuitInput,
            path.join(
                path.resolve(),
                "/zk-resources/wasm/tally-contribution_dim3.wasm"
            ),
            path.join(
                path.resolve(),
                "/zk-resources/zkey/tally-contribution_dim3_final.zkey"
            )
        );
        proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
        await _.DKG.connect(committee).submitTallyContribution(requestID, [
            committeeIndex,
            tallyContribution.D,
            proof,
        ]);
        console.log(
            `Committee member ${committeeIndex} submitted tally contribution`
        );
    }
    console.log(
        "TallyTracker state:",
        await _.DKG.getTallyTrackerState(requestID)
    );
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
