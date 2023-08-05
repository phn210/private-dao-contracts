import { deploy } from "../deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false, false);

    const daoIDs = [0, 1, 2];

    for (let i = 0; i < daoIDs.length; i++) {
        let daoAddress = await _.DAOManager.daos(daoIDs[i]);

        await _.DAOManager.applyForFundingDev(daoAddress);

        console.log(`DAO ${daoIDs[i]} applied for next funding round!`);
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
