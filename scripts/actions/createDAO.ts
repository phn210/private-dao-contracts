import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const NEW_NUM_DAOS = 3;
    let CURRENT_NUM_DAOS = Number(await _.DAOManager.daoCounter());
    let descriptionHash = "0xC4F8E201EEDB88D8885D83FB8AD14E51D100286D129A6BC6BADB55962195F095";
    console.log(CURRENT_NUM_DAOS);
    await _.DAOManager.createDAO(
        CURRENT_NUM_DAOS,
        config.daoConfig,
        descriptionHash
    );
    console.log(`Create DAO ${CURRENT_NUM_DAOS}!`);
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
