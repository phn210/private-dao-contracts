import { expect } from "chai";
import { ethers, network } from "hardhat";
// @ts-ignore
import * as snarkjs from "snarkjs";
import { loadAllContracts } from "./constants/address";
import { CommitteeData } from "../test/data";
import { Committee } from "../libs/index";
import { Utils } from "../libs/utils";

var dim = 3;
var t = 3;
var n = 5;
// committeeIndex from 1 to n
var fundingRoundID = 0;

async function main() {
    let chainID = String(network.config.chainId);
    let accounts = await ethers.getSigners();
    let founder = accounts[0];
    let contracts = await loadAllContracts(founder, chainID);

    let fundingRound = await contracts.fundManager.fundingRounds(
        fundingRoundID
    );
    let requestID = fundingRound.requestID;
    let fundingRoundState = await contracts.fundManager.getFundingRoundState(
        fundingRoundID
    );
    console.log("Funding round state: ", fundingRoundState);
    console.log(
        "You can only call finalizeFundingRound when the funding round state is FAILED or SUCCEEDED."
    );
    await contracts.fundManager.finalizeFundingRound(fundingRoundID);

    console.log("After finalized, DAO can call withdrawFund");
}

main().then(() => {
    console.log("DONE");
});
