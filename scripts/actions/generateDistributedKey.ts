import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    enum KeyType {
        Funding,
        Voting
    }

    const keyType = KeyType.Funding;
    const dimension = 3;
    const numKeys = 5;

    for (let i = 0; i < numKeys; i++) {
        let keyId = await _.DKG.distributedKeyCounter();
        // await _.DKG.generateDistributedKey(dimension, keyType);
        console.log("Generated Key ID:", keyId);
    }
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
