import crypto from 'crypto';
import { ethers } from "hardhat";
import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const daoId = 0;
    const proposalData = {
        shortDes: "Apply for funding round proposal",
        actions: [
            {
                target: _.DAOManager.address,
                value: 0,
                signature: "applyForFunding()",
                data: "0x",
            },
        ],
        descriptionHash: '0x'+crypto.randomBytes(32).toString('hex')
    };

    const daoAddress = _.DAOManager.daos(daoId);
    const dao = _.DAO.attach(daoAddress);

    console.log(`Creating proposal for DAO ${dao.address}`);
    const proposalId = dao.hashProposal(
        proposalData.actions,
        proposalData.descriptionHash
    );

    await dao.propose(
        proposalData.actions,
        proposalData.descriptionHash
    );
    
    const proposalState = await dao.state(proposalId);
    if (proposalState == 0) console.log(`Created new proposal`);
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
