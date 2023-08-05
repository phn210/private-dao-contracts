import crypto from "crypto";
import { ethers } from "hardhat";
import { deploy } from "../deploy-with-check";

const daoID = 0;

async function main() {
    const { _, $, t, n, config } = await deploy(false, false);
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
        descriptionHash:
            "0xc4f8e201eedb88d8885d83fb8ad14e51d100286d129a6bc6badb55962195f095",
    };

    const daoAddress = await _.DAOManager.daos(daoID);
    const dao = _.DAO.attach(daoAddress);

    const proposalId = await dao.hashProposal(
        proposalData.actions,
        proposalData.descriptionHash
    );

    await dao.propose(proposalData.actions, proposalData.descriptionHash);

    const proposalState = await dao.state(proposalId);
    if (proposalState == 0) console.log(`Created new proposal ${proposalId}`);
}
main().then(() => {
    console.log("DONE");
    process.exit();
});
