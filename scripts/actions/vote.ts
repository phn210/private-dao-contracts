// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../1-deploy-with-check";
import { Voter } from "../../libs/index";
import { Utils } from "../../libs/utils";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const daoIndex = 0;
    const proposalIndex = 0;
    const keyID = 0;
    // in ETH
    const fundingAmount = '0.01';
    const votingPower = BigInt(Number(ethers.utils.parseEther(fundingAmount)));
    const votingVector = [
        [0, 1, 0],
        [1, 0, 0],
        [0, 1, 0],
        [0, 1, 0],
        [0, 0, 1],
    ];

    const daoAddress = await _.DAOManager.daos(daoIndex);

    const dao = _.DAO.attach(daoAddress);
    console.log("DAO:", dao.address);


    console.log("Proposal", proposalIndex);
    const proposalId = await dao.proposalIds(proposalIndex);
    console.log("State", await dao.state(proposalId));

    let [publicKeyX, publicKeyY] = await _.DKG.getPublicKey(
        keyID
    );
    publicKeyX = BigInt(publicKeyX);
    publicKeyY = BigInt(publicKeyY);

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
