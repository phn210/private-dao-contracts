import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const daoIndexes = 0;
    const proposalIndexes = [0];

    const daoAddress = await _.DAOManager.daos(daoIndexes);

    const dao = _.DAO.attach(daoAddress);
    console.log("DAO:", dao.address);

    for(let i = 0; i < proposalIndexes.length; i++) {
        console.log("Proposal", proposalIndexes[i]);
        let proposalId = await dao.proposalIds(proposalIndexes[i]);
        console.log(await dao.proposals(proposalId));
        console.log("State", await dao.state(proposalId));
    }
}

main().then(() => {
    // console.log("DONE");
    process.exit();
});
