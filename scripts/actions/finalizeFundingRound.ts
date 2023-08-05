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

    const fundingRoundID = 0;
    
    console.log(
        `Funding Round ${fundingRoundID} State:`,
        await _.FundManager.getFundingRoundState(fundingRoundID)
    );

    let tx = await _.FundManager.finalizeFundingRound(fundingRoundID);
    await tx.wait();
    console.log('Funding round is finalized');
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
