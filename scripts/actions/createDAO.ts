import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const NEW_NUM_DAOS = 3;
    let CURRENT_NUM_DAOS = Number(await _.DAOManager.daoCounter());
    
    console.log(CURRENT_NUM_DAOS);

    if (CURRENT_NUM_DAOS == 0) await _.DAOManager.setDistributedKeyId(0);

    for (let i = 0; i < NEW_NUM_DAOS - CURRENT_NUM_DAOS; i++) {
        await _.DAOManager.createDAO(config.daoConfig);
        console.log(`Create DAO ${i + CURRENT_NUM_DAOS}!`);
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
