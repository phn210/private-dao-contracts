import { deploy } from "../1-deploy-with-check";
import { CommitteeData } from "../../test/data";
import { Committee } from "../../libs/index";
import { Utils } from "../../libs/utils";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const committeeIndexes = [1, 2, 3, 4, 5];
    const preset = true;
    const keyID = 0;

    for (let i = 0; i < committeeIndexes.length; i++) {
        let committeeIndex = committeeIndexes[i];
        let committee = $.committee[committeeIndex-1];
        let committeeData;
        if (preset) {
            committeeData = CommitteeData.data1[committeeIndex - 1];
        } else {
            committeeData = Committee.getRandomPolynomial(committeeIndex, t, n);
        }

        // console.log("Committee data: ", Utils.logFullObject(committeeData));
        // console.log(
        //     "If this is newly generated data, then copy it to /test/data.ts at the corresponding position according to the committeeIndex for use in subsequent steps."
        // );
        let x = [];
        let y = [];
        for (let i = 0; i < t; i++) {
            x.push(committeeData.C[i][0]);
            y.push(committeeData.C[i][1]);
        }
        await _.DKG.connect(committee).submitRound1Contribution(keyID, [x, y]);
        console.log(`Committee ${committeeIndex} submitted round 1 contribution`);
    }
    
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
