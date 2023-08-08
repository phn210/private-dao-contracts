// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { ethers } from "hardhat";
import { deploy } from "../deploy-with-check";
import { CommitteeData } from "../../test/mock-data";
import { Committee, Utils } from "distributed-key-generation";
import bigInt from "big-integer";
import axios from "axios";

const daoIndex = 0;
const proposalIndex = 0;
async function main() {
    const { _, $, t, n, config } = await deploy(false, false);
    const daoAddress = await _.DAOManager.daos(daoIndex);
    const dao = _.DAO.attach(daoAddress);
    console.log("DAO: ", dao.address);
    console.log("Proposal index: ", proposalIndex);
    const proposalID = await dao.proposalIDs(proposalIndex);
    console.log("Proposal ID: ", proposalID);
    console.log("Proposal state: ", await dao.state(proposalID));
    let proposal = await dao.proposals(proposalID);

    let tx = await dao.finalize(proposalID);
    await tx.wait();

    console.log("Proposal is finalized!");
    console.log("Proposal state: ", await dao.state(proposalID));
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
