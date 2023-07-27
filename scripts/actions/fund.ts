// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../deploy-with-check";
import { Voter, Utils } from "distributed-key-generation";
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
    let keyID = await _.FundManager.getDistributedKeyID(fundingRound.requestID);
    console.log(`This funding round use distributed key ${keyID}`);
    let [publicKeyX, publicKeyY] = await _.DKG.getPublicKey(keyID);
    publicKeyX = BigInt(publicKeyX);
    publicKeyY = BigInt(publicKeyY);
    let tmp = await _.FundManager.getListDAO(fundingRoundID);
    let listDAO = [];
    for (let i = 0; i < tmp.length; i++) {
        listDAO.push(BigInt(tmp[i]));
    }
    for (let i = 0; i < $.voters.length; i++) {
        let voterData = {
            votingPower: VoterData[0].votingPower[i],
            fundingVector: VoterData[0].fundingVector[i],
            votingVector: VoterData[0].votingPower[i],
        };
        let fund = Voter.getFund(
            [publicKeyX, publicKeyY],
            listDAO,
            voterData.votingPower,
            voterData.fundingVector
        );
        let { proof, publicSignals } = await snarkjs.groth16.fullProve(
            fund.circuitInput,
            path.join(path.resolve(), "/zk-resources/wasm/fund_dim3.wasm"),
            path.join(path.resolve(), "/zk-resources/zkey/fund_dim3_final.zkey")
        );
        proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
        await _.FundManager.connect($.voters[i]).fund(
            fundingRoundID,
            fund.commitment,
            fund.Ri,
            fund.Mi,
            proof,
            {
                value: voterData.votingPower.toString(),
            }
        );

        console.log("Investor", $.voters[i].address, "funded!");
        Utils.logFullObject({
            amount: voterData.votingPower.toString(),
            fundingVector: voterData.fundingVector,
            commitment: fund.commitment,
        });
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
