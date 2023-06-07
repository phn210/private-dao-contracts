import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const keyID = 2;

    const fundingRoundID = await _.FundManager.fundingRoundCounter();
    console.log(fundingRoundID);
    // await _.FundManager.launchFundingRound(keyID);

    // console.log(
    //     "FundingRoundState:",
    //     await _.FundManager.getFundingRoundState(fundingRoundID)
    // );

    // console.log("FundingRound:", await _.FundManager.fundingRounds(fundingRoundID));
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
