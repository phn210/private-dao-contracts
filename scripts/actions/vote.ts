// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../deploy-with-check";
import { Voter, Utils } from "distributed-key-generation";
import { VoterData } from "../../test/mock-data";
import axios from "axios";

const applicationServerURL = process.env.APPLICATION_SERVER_URL;
const daoIndex = 0;
const proposalIndex = 0;
const eligibleVoterIndexes = [0, 1, 2];
async function main() {
    let investmentPathRequest = await axios.post(
        applicationServerURL + "/investment/paths"
    );
    let merkleTreePath = investmentPathRequest.data.data;

    const { _, $, t, n, config } = await deploy(false, false);

    const daoAddress = await _.DAOManager.daos(daoIndex);
    const dao = _.DAO.attach(daoAddress);
    console.log("DAO: ", dao.address);
    console.log("Proposal index: ", proposalIndex);
    const proposalID = await dao.proposalIDs(proposalIndex);
    console.log("Proposal ID: ", proposalID);
    console.log("Proposal state", await dao.state(proposalID));
    let proposal = await dao.proposals(proposalID);
    let requestID = proposal.requestID;
    let request = await dao.requests(requestID);
    let keyID = request.distributedKeyID;

    let [publicKeyX, publicKeyY] = await _.DKG.getPublicKey(keyID);
    publicKeyX = BigInt(publicKeyX);
    publicKeyY = BigInt(publicKeyY);

    let voterData = [];
    for (let i = 0; i < $.voters.length; i++) {
        voterData.push({
            votingPower: VoterData[0].votingPower[i],
            fundingVector: VoterData[0].fundingVector[i],
            votingVector: VoterData[0].votingVector[i],
            commitment: VoterData[0].commitment[i],
            nullifier: VoterData[0].nullifier[i],
        });
    }
    for (let i = 0; i < eligibleVoterIndexes.length; i++) {
        let voterIndex = eligibleVoterIndexes[i];
        let path = merkleTreePath[voterData[voterIndex].commitment.toString()];

        let vote = Voter.getVote(
            Utils.getBigIntArray([publicKeyX, publicKeyY]),
            BigInt(dao.address),
            BigInt(proposalID),
            voterData[voterIndex].votingVector,
            voterData[voterIndex].votingPower,
            voterData[voterIndex].nullifier,
            path.pathElements,
            path.pathIndices,
            path.pathRoot
        );
        // console.log(vote);
        let { proof, publicSignals } = await snarkjs.groth16.fullProve(
            vote.circuitInput,
            __dirname + "/../zk-resources/wasm/vote_dim3.wasm",
            __dirname + "/../zk-resources/zkey/vote_dim3_final.zkey"
        );
        proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
        let voteData = [
            path.pathRoot,
            vote.circuitInput.nullifierHash,
            vote.Ri,
            vote.Mi,
            proof,
        ];
        console.log(publicSignals);
        await dao.castVote(proposalID, voteData);
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
