import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    console.log(
        "Funding round counter",
        await _.FundManager.fundingRoundCounter()
    );
    console.log("Number of DAOs in applied queue", await _.QUEUE.getLength());
    const fundingRoundIds = [0];

    for (let i = 0; i < fundingRoundIds.length; i++) {
        console.log("Funding Round", fundingRoundIds[i]);
        console.log(await _.FundManager.fundingRounds(fundingRoundIds[i]));
        console.log(
            "State",
            await _.FundManager.getFundingRoundState(fundingRoundIds[i])
        );
        console.log();
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
