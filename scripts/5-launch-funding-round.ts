import { expect } from "chai";
import { ethers, network } from "hardhat";
import { loadAllContracts } from "./constants/address";
import { CommitteeData } from "../test/data";
import { Committee } from "../libs/index";
import { Utils } from "../libs/utils";

var t = 3;
var n = 5;
// committeeIndex from 1 to n
var committeeIndex = 1;
var keyID = 0;

async function main() {
    let chainID = String(network.config.chainId);
    let accounts = await ethers.getSigners();
    let founder = accounts[0];
    let fakeDAOs = [];
    for (let i = 0; i < 3; i++) {
        fakeDAOs.push(accounts[1 + n + i]);
    }
    let contracts = await loadAllContracts(founder, chainID);

    for (let i = 0; i < 3; i++) {
        await contracts.fundManager.addWhitelistedDAO(fakeDAOs[i].address);
    }
    for (let i = 0; i < 3; i++) {
        await contracts.fundManager.connect(fakeDAOs[i]).applyForFunding();
    }

    let fundingRoundID = await contracts.fundManager.fundingRoundCounter();

    console.log("FundingRound ID: ", fundingRoundID);
    await contracts.fundManager.launchFundingRound(keyID);
    console.log(
        "FundingRoundState: ",
        await contracts.fundManager.getFundingRoundState(fundingRoundID)
    );
    console.log(
        "After launching the funding round, it is necessary to go through a PENDING period (The number of blocks to wait depends on the config when initializing the FundManager). Only when the FundingRound is in the ACTIVE state can funding be executed."
    );
    // let fundingRound = await contracts.fundManager.fundingRounds(fundingRoundID);
    // let requestID = fundingRound.requestID;
    // keyID = await contracts.fundManager.getDistributedKeyID(requestID);
    // Voter will use this keyID to get publickey for fund
}

main().then(() => {
    console.log("DONE");
});
