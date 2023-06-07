import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const fundingRoundIds = [1];

    for(let i = 0; i < fundingRoundIds.length; i++) {
        console.log("Funding Round", fundingRoundIds[i]);
        console.log(await _.FundManager.fundingRounds(fundingRoundIds[i]));
        console.log("State", await _.FundManager.getFundingRoundState(fundingRoundIds[i]));
        console.log();
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
