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
var mockData = true;
var keyID = 0;

async function main() {
    let chainID = String(network.config.chainId);
    let accounts = await ethers.getSigners();
    let committee = accounts[committeeIndex];
    let contracts = await loadAllContracts(committee, chainID);
    let committeeData;
    if (mockData) {
        committeeData = CommitteeData.data1[committeeIndex - 1];
    } else {
        committeeData = Committee.getRandomPolynomial(committeeIndex, t, n);
    }

    console.log("Committee data: ", Utils.logFullObject(committeeData));
    console.log(
        "If this is newly generated data, then copy it to /test/data.ts at the corresponding position according to the committeeIndex for use in subsequent steps."
    );
    let x = [];
    let y = [];
    for (let i = 0; i < t; i++) {
        x.push(committeeData.C[i][0]);
        y.push(committeeData.C[i][1]);
    }
    await contracts.dkgContract.submitRound1Contribution(keyID, [x, y]);
}

main().then(() => {
    console.log("DONE");
});
