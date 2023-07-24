// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../1-deploy-with-check";
import { Voter } from "../../libs/index";
import { Utils } from "../../libs/utils";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const fundingRoundID = 0;
    const keyID = 0;
    // in ETH
    const fundingAmount = '0.01';
    const fundingValue = BigInt(Number(ethers.utils.parseEther(fundingAmount)));
    const fundingVector = [
        [1, 0, 0],
        [1, 0, 0],
        [0, 1, 0],
        [0, 1, 0],
        [0, 0, 1],
    ];

    console.log(
        `Funding Round ${fundingRoundID} State:`,
        await _.FundManager.getFundingRoundState(fundingRoundID)
    );
    let [publicKeyX, publicKeyY] = await _.DKG.getPublicKey(
        keyID
    );
    publicKeyX = BigInt(publicKeyX);
    publicKeyY = BigInt(publicKeyY);
    let tmp = await _.FundManager.getListDAO(fundingRoundID);
    let listDAO = [];
    for (let i = 0; i < tmp.length; i++) {
        listDAO.push(BigInt(tmp[i]));
    }
    for (let i = 0; i < $.voters.length; i++) {
        let fund = Voter.getFund(
            [publicKeyX, publicKeyY],
            listDAO,
            fundingValue,
            fundingVector[i]
        );
        let { proof, publicSignals } = await snarkjs.groth16.fullProve(
            fund.circuitInput,
            path.join(path.resolve(), '/zk-resources/wasm/fund_dim3.wasm'),
            path.join(path.resolve(), '/zk-resources/zkey/fund_dim3_final.zkey')
        );
        proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
        await _.FundManager.connect($.voters[i]).fund(
            fundingRoundID,
            fund.commitment,
            fund.Ri,
            fund.Mi,
            proof,
            {
                value: fundingValue,
            }
        );

        console.log('Investor', $.voters[i].address, 'funded!');
        console.log(Utils.logFullObject({
            amount: fundingValue,
            fundingVector: fundingVector[i],
            commitment: fund.commitment
        }));
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
