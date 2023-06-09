import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const keyID = 10;

    const fundingRoundID = await _.FundManager.fundingRoundCounter();
    
    await _.FundManager.launchFundingRound(keyID);
    console.log("Launched funding round", fundingRoundID);
    console.log(
        "FundingRoundState:",
        await _.FundManager.getFundingRoundState(fundingRoundID)
    );

    console.log("FundingRound:", await _.FundManager.fundingRounds(fundingRoundID));
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
