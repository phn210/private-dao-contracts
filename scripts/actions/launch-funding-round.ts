import { deploy } from "../deploy-with-check";

const keyID = 1;
async function main() {
    const { _, $, t, n, config } = await deploy(false, false);

    const fundingRoundID = await _.FundManager.fundingRoundCounter();
    await _.FundManager.launchFundingRound(keyID);
    console.log("Launched funding round", fundingRoundID);
    console.log(
        "FundingRound:",
        await _.FundManager.fundingRounds(fundingRoundID)
    );
    console.log(
        "FundingRoundState:",
        await _.FundManager.getFundingRoundState(fundingRoundID)
    );
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
