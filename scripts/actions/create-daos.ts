import { deploy } from "../deploy-with-check";

const NEW_NUM_DAOS = 3;
const keyID = 0;
async function main() {
    const { _, $, t, n, config } = await deploy(false, false);

    let descriptionHash =
        "0xc4f8e201eedb88d8885d83fb8ad14e51d100286d129a6bc6badb55962195f095";
    console.log("Setting distributed key ID of DAOManager to ", keyID);
    await _.DAOManager.setDistributedKeyID(keyID);
    console.log("Creating more ", NEW_NUM_DAOS, " DAOs");
    for (let i = 0; i < NEW_NUM_DAOS; i++) {
        let currentNumDAOs = await _.DAOManager.daoCounter();
        await _.DAOManager.createDAO(
            currentNumDAOs,
            config.daoConfig,
            descriptionHash
        );
        console.log(`Create DAO ${currentNumDAOs}!`);
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
