
import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    //const numDAOs = await _.DAOMananger.daoCounter();
    const numDAOs = 3;
    console.log("Number of DAO created:", numDAOs);;

    for(let i = 0; i < numDAOs; i++) {
        console.log("DAO", i + ":", await _.DAOManager.daos(i));
        //let daoAddress = await _.DAOManager.daos(i);
        //console.log(await dao.proposals(proposalId));
        //console.log("State", await dao.state(proposalId));
    }
}

main().then(() => {
    // console.log("DONE");
    process.exit();
});
