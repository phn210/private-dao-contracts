import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const fundingRoundID = 0;

    const listDAO = await _.FundManager.getListDAO(fundingRoundID);
    const balances = await _.FundManager.getFundingRoundBalance(fundingRoundID);
    console.log(listDAO, balances)

    for (let i = 0; i < listDAO.length; i++) {
        console.log(`DAO ${listDAO[i]} was funded`);
        await _.FundManager.connect($.voters[i]).withdrawFund(fundingRoundID, listDAO[i]);
        console.log(`DAO ${listDAO[i]} withdrew fund!`);
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
