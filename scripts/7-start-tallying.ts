import { expect } from "chai";
import { ethers, network } from "hardhat";
// @ts-ignore
import * as snarkjs from "snarkjs";
import { loadAllContracts } from "./constants/address";
import { CommitteeData, VoterData } from "../test/data";
import { Committee, Voter } from "../libs/index";
import { Utils } from "../libs/utils";

var t = 3;
var n = 5;
var fundingRoundID = 0;
var keyID = 0;

async function main() {
    let chainID = String(network.config.chainId);
    let accounts = await ethers.getSigners();
    let founder = accounts[0];
    let contracts = await loadAllContracts(founder, chainID);

    console.log(
        "FundingRoundState: ",
        await contracts.fundManager.getFundingRoundState(fundingRoundID)
    );
    console.log("Can only start tallying if fundingRound is in TALLYING state");
    await contracts.fundManager.startTallying(fundingRoundID);
}

main().then(() => {
    console.log("DONE");
});
