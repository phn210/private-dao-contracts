// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../deploy-with-check";

const fundingRoundID = 0;
async function main() {
    const { _, $, t, n, config } = await deploy(false, false);
    console.log(
        `Funding Round ${fundingRoundID} State:`,
        await _.FundManager.getFundingRoundState(fundingRoundID)
    );

    await _.FundManager.finalizeFundingRound(fundingRoundID);
    console.log(`Funding round ${fundingRoundID} is finalized`);

    if (Number(await _.FundManager.getFundingRoundState(fundingRoundID)) == 4) {
        console.log(`Because funding round ${fundingRoundID} is succeeded, DAOs can withdraw fund.`);
        const totalFunded = await _.FundManager.getFundingRoundBalance(
            fundingRoundID
        );
        console.log(`${totalFunded} will be distributed to DAOs`);
        console.log("Withdrawing fund for DAOs in the funding round . . . ");
        const listDAO = await _.FundManager.getListDAO(fundingRoundID);
        for (let i = 1; i < listDAO.length; i++) {
            console.log(`DAO ${listDAO[i]} was funded`);
            await _.FundManager.withdrawFund(fundingRoundID, listDAO[i]);
            console.log(`DAO ${listDAO[i]} withdrew fund!`);
        }
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
