import { expect } from "chai";
import { ethers, network } from "hardhat";
import { loadAllContracts } from "./constants/address";

async function main() {
    let accounts = await ethers.getSigners();
    let founder = accounts[0];
    let chainID = String(network.config.chainId);
    let contracts = await loadAllContracts(founder, chainID);
    
    let keyType = 0;
    // 0 is FUNDING
    // 1 IS VOTING
    let dimension = 3;
    console.log(
        "Key ID: ",
        await contracts.dkgContract.distributedKeyCounter()
    );
    await contracts.dkgContract.generateDistributedKey(dimension, keyType);
}

main().then(() => {
    console.log("DONE");
});
