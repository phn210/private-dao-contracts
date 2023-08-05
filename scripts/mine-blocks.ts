import { ethers, network } from "hardhat";

async function bn() {
    let _bn = await ethers.provider.getBlockNumber();
    // console.log("\x1b[33m%s\x1b[0m", "Block =", _bn.toString());
    return _bn;
}

async function mineBlocks(nums: number) {
    // console.log(`Skipping ${nums} blocks...`);
    console.log("Block before:", await bn());
    for (let i = 0; i < nums; i++) await ethers.provider.send("evm_mine", []);
    console.log("Block after:", await bn());
}

async function main() {
    await mineBlocks(60);
}

main().then(() => {
    console.log("Mine DONE!");
});
