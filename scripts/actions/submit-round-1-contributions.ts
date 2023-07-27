import { deploy } from "../deploy-with-check";
import { CommitteeData } from "../../test/mock-data";
import { Committee, Utils } from "distributed-key-generation";

const keyID = 1;
async function main() {
    const { _, $, t, n, config } = await deploy(false, false);

    const committeeIndexes = [1, 2, 3, 4, 5];
    const preset = true;

    for (let i = 0; i < committeeIndexes.length; i++) {
        let committeeIndex = committeeIndexes[i];
        let committee = $.committee[committeeIndex - 1];
        let committeeData;
        if (preset) {
            committeeData = CommitteeData[0][i];
        } else {
            committeeData = Committee.getRandomPolynomial(t, n);
        }

        // console.log("Committee data: ");
        // Utils.logFullObject(committeeData)
        // console.log(
        //     "If this is not mock data, then copy it to /test/mock-data.ts at the corresponding position according to the committeeIndex for use in subsequent steps."
        // );
        let x = [];
        let y = [];
        for (let i = 0; i < t; i++) {
            x.push(committeeData.C[i][0]);
            y.push(committeeData.C[i][1]);
        }
        await _.DKG.connect(committee).submitRound1Contribution(keyID, [x, y]);
        console.log(
            `Committee ${committeeIndex} submitted round 1 contribution`
        );
    }

    console.log("Distributed key: ", await _.DKG.distributedKeys(keyID));
    console.log(
        "Distributed key state: ",
        await _.DKG.getDistributedKeyState(keyID)
    );
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
