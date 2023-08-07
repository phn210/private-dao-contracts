import { ethers, network } from "hardhat";
import { deploy } from "../deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false, false);
    const queueLength = Number(await _.Queue.getLength());
    console.log("Number of DAOs in applied queue:", queueLength);
    console.log("List DAOs in queue:");
    console.log(await _.Queue.getQueue());
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
