// @ts-ignore
import * as snarkjs from "snarkjs";
import path from "path";
import { deploy } from "../1-deploy-with-check";
import { CommitteeData } from "../../test/data";
import { Committee } from "../../libs/index";
import { Utils } from "../../libs/utils";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const committeeIndexes = [1, 2, 3, 4, 5];
    const preset = true;
    const keyID = 2;

    for (let i = 0; i < committeeIndexes.length; i++) {
        let committeeIndex = committeeIndexes[i];
        let committee = $.committee[committeeIndex-1];
        let committeeData;
        if (preset) {
            committeeData = CommitteeData.data1[committeeIndex - 1];
        } else {
            committeeData = Committee.getRandomPolynomial(committeeIndex, t, n);
        }

        let listCommitteeIndex = [];
        for (let j = 1; j <= n; j++) {
            if (j != committeeIndex) {
                listCommitteeIndex.push(j);
            }
        }

        let round1DataSubmissions = await _.DKG.getRound1DataSubmissions(keyID);
        let recipientIndexes = [];
        let recipientPublicKeys = [];
        let f = [];

        for (let j = 0; j < round1DataSubmissions.length; j++) {
            let round1DataSubmission = round1DataSubmissions[j];
            let recipientIndex = round1DataSubmission.senderIndex;
            if (recipientIndex != committeeIndex) {
                recipientIndexes.push(recipientIndex);
                let recipientPublicKeyX = BigInt(round1DataSubmission.x[0]);
                let recipientPublicKeyY = BigInt(round1DataSubmission.y[0]);
                recipientPublicKeys.push([
                    recipientPublicKeyX,
                    recipientPublicKeyY,
                ]);
                // @ts-ignore
                f.push(BigInt(committeeData.f[recipientIndex]));
            }
        }

        let round2Contribution = Committee.getRound2Contributions(
            recipientIndexes,
            recipientPublicKeys,
            f,
            committeeData.C
        );

        let ciphers = round2Contribution.ciphers;
        
        let { proof, publicSignals } = await snarkjs.groth16.fullProve(
            round2Contribution.circuitInput,
            // path.join(path.dirname(path.resolve()))
            path.join(path.resolve(), '/zk-resources/wasm/round-2-contribution.wasm'),
            path.join(path.resolve(), '/zk-resources/zkey/round-2-contribution_final.zkey')
        );

        proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
        
        await _.DKG.connect(committee).submitRound2Contribution(keyID, [
            committeeIndex,
            recipientIndexes,
            ciphers,
            proof,
        ]);
        console.log(`Committee ${committeeIndex} submitted round 2 contribution`);
    }
    
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
