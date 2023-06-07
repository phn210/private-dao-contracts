// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../1-deploy-with-check";
import { Voter } from "../../libs/index";
import { Utils } from "../../libs/utils";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const fundingRoundID = 2;

    for (let i = 0; i < $.voters.length; i++) {
        await _.FundManager.connect($.voters[i]).refund(fundingRoundID);
        console.log('Investor', $.voters[i].address, 'refunded!');
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
