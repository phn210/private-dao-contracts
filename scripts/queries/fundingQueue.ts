import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const queueLength = await _.QUEUE.getLength()
    console.log("Number of DAOs in applied queue:", Number(queueLength));
    console.log("List DAOs in queue:");
    // for(let i = 0; i < queueLength; i++) {
    //     console.log(await _.QUEUE.first());
    // }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
