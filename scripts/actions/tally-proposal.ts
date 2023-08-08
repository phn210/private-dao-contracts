// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../deploy-with-check";
import { CommitteeData } from "../../test/mock-data";
import { Committee, Utils } from "distributed-key-generation";

const committeeIndexes = [1, 2, 4];
const daoIndex = 0;
const proposalIndex = 0;
async function main() {
    const { _, $, t, n, config } = await deploy(false, false);
    const daoAddress = await _.DAOManager.daos(daoIndex);
    const dao = _.DAO.attach(daoAddress);
    console.log("DAO: ", dao.address);
    console.log("Proposal index: ", proposalIndex);
    const proposalID = await dao.proposalIDs(proposalIndex);
    console.log("Proposal ID: ", proposalID);
    console.log("Proposal state: ", await dao.state(proposalID));
    let proposal = await dao.proposals(proposalID);
    let requestID = proposal.requestID;
    let request = await dao.requests(requestID);
    let keyID = request.distributedKeyID;

    await dao.tally(proposalID);
    console.log("Proposal is tallying");

    console.log("Proposal state ", await dao.state(proposalID));

    console.log(`This proposal use distributed key ${keyID}`);

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
        let tx = await _.DKG.connect(committee).submitTallyContribution(requestID, [
            committeeIndex,
            tallyContribution.D,
            proof,
        ]);
        await tx.wait();
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
