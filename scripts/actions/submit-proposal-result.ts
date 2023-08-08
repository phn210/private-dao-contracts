// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../deploy-with-check";
import { CommitteeData } from "../../test/mock-data";
import { Committee, Utils } from "distributed-key-generation";
import bigInt from "big-integer";
import axios from "axios";

const minimalUnit = bigInt(
    Number(process.env.MINIMAL_UNIT || 10000000000000000n)
);
const applicationServerURL = process.env.APPLICATION_SERVER_URL;
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

    console.log(`This proposal use distributed key ${keyID}`);
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
    // let result = [...Array(dim).keys()].map((index: any) => 0n);
    // for (let i = 0; i < $.voters.length; i++) {
    //     let voterData = {
    //         votingPower: VoterData[0].votingPower[i],
    //         fundingVector: VoterData[0].fundingVector[i],
    //         votingVector: VoterData[0].votingVector[i],
    //     };

    //     for (let j = 0; j < dim; j++) {
    //         result[j] +=
    //             voterData.votingPower * BigInt(voterData.fundingVector[j]);
    //     }
    // }

    (BigInt.prototype as any).toJSON = function () {
        return this.toString();
    };
    let bruteForcesRequest = await axios.post(
        applicationServerURL + "/committee/brute-forces",
        {
            resultVector: resultVector,
        }
    );

    let result = bruteForcesRequest.data.data.result;
    for (let i = 0; i < result.length; i++) {
        result[i] = Utils.getBigInt(bigInt(result[i]).multiply(minimalUnit));
    }

    console.log(`Result ${result} will be submitted`);
    let lagrangeCoefficient = Utils.getBigIntArray(
        Committee.getLagrangeCoefficient(listIndex)
    );
    let { proof, publicSignals } = await snarkjs.groth16.fullProve(
        {
            lagrangeCoefficient: lagrangeCoefficient,
            D: D,
            M: M,
            result: result,
        },
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
    let tx = await _.DKG.submitTallyResult(requestID, result, proof);
    await tx.wait();
    console.log("Proposal result is submitted");

    console.log(
        "TallyTracker state:",
        await _.DKG.getTallyTrackerState(requestID)
    );
    console.log("Proposal state: ", await dao.state(proposalID));
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
