import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    console.log("Funding round counter", await _.FundManager.fundingRoundCounter());
    console.log("Number of DAOs in applied queue", await _.QUEUE.getLength());
    const fundingRoundIds = [6];

    console.log(await _.FundManager.checkUpkeep("0x"));    
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
