import { deploy } from "../deploy-with-check";

enum KeyType {
    Funding,
    Voting,
}
const dimension = 3;
const numKeys = 1;
const keyType = KeyType.Funding;

async function main() {
    const { _, $, t, n, config } = await deploy(false, false);
    enum KeyType {
        Funding,
        Voting,
    }
    let keyType = KeyType.Funding;
    const dimension = 3;
    const numKeys = 5;
enum KeyType {
    Funding,
    Voting,
}
const dimension = 3;
const numKeys = 1;
const keyType = KeyType.Funding;

async function main() {
    const { _, $, t, n, config } = await deploy(false, false);

    for (let i = 0; i < numKeys; i++) {
        let keyID = await _.DKG.distributedKeyCounter();
        let tx = await _.DKG.generateDistributedKey(dimension, keyType);
        await tx.wait();
        console.log("Generated key with type ", keyType, " and ID ", keyID);
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
