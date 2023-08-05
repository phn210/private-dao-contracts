import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const daoIds = [0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2];

    for (let i = 0; i < daoIds.length; i++) {
        let daoAddress = await _.DAOManager.daos(daoIds[i]);
        
        await _.DAOManager.applyForFundingDev(daoAddress);

        console.log(`DAO ${daoIds[i]} applied for next funding round!`);
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
