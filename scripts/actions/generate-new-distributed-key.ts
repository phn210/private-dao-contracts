import { deploy } from "../deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false, false);
    enum KeyType {
        Funding,
        Voting,
    }
    let keyType = KeyType.Funding;
    const dimension = 3;
    const numKeys = 1;
    for (let i = 0; i < numKeys; i++) {
        let keyID = await _.DKG.distributedKeyCounter();
        await _.DKG.generateDistributedKey(dimension, keyType);
        console.log("Generated key with type ", keyType, " and ID ", keyID);
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
