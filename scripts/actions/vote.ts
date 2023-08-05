// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../deploy-with-check";
import { Voter, Utils } from "distributed-key-generation";
import { VoterData } from "../../test/mock-data";

const daoIndex = 0;
const proposalIndex = 0;
const eligibleVoterIndexes = [0, 1, 2];
async function main() {
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

    for (let i = 0; i < eligibleVoterIndexes.length; i++) {
        let voterIndex = eligibleVoterIndexes[i];
        let voter = $.voters[i];
        let voterData = {
            votingPower: VoterData[0].votingPower[voterIndex],
            fundingVector: VoterData[0].fundingVector[voterIndex],
            votingVector: VoterData[0].votingVector[voterIndex],
            commitment: VoterData[0].commitment[voterIndex],
            nullifier: VoterData[0].nullifier[voterIndex],
        }
    }
    // for (let i = 0; i < $.voters.length; i++) {
    //     let index = this.tree.indexOf(this.commitments[eligibleVoters[i]]);
    //     console.log(index);
    //     let path = this.tree.path(index);

    //     let vote = Voter.getVote(
    //         Utils.getBigIntArray([publicKeyX, publicKeyY]),
    //         BigInt(this.firstDAO.address),
    //         BigInt(proposalHash),
    //         VoterData.data1.votingVector[eligibleVoters[i]],
    //         VoterData.data1.votingPower[eligibleVoters[i]],
    //         this.votingNullifiers[eligibleVoters[i]],
    //         path.pathElements,
    //         path.pathIndices,
    //         this.tree.root
    //     );
    //     // console.log(vote);
    //     let { proof, publicSignals } = await snarkjs.groth16.fullProve(
    //         vote.circuitInput,
    //         __dirname + "/../zk-resources/wasm/vote_dim3.wasm",
    //         __dirname + "/../zk-resources/zkey/vote_dim3_final.zkey"
    //     );
    //     proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
    //     let voteData = [
    //         this.tree.root,
    //         vote.nullifierHash,
    //         vote.Ri,
    //         vote.Mi,
    //         proof
    //     ];
    //     console.log(publicSignals);
    //     await this.firstDAO.castVote(
    //         proposalHash,
    //         voteData
    //     );
    // }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
