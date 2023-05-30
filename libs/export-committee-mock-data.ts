import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { Committee } from ".";

var t = 3;
var n = 5;
var filename = "output.json";

let committees = new Array();
for (let i = 1; i <= n; i++) {
    committees.push(Committee.getRandomPolynomial(i, t, n));
}

let round2Contribute: any[][] = new Array(n + 1);
for (let i = 0; i < n + 1; i++) {
    round2Contribute[i] = new Array(n + 1);
}
for (let i = 0; i < n; i++) {
    committees[i]["index"] = (i + 1).toString();
    committees[i]["round2Contribution"] = {};
    let indexI = i + 1;
    for (let j = 0; j < n; j++) {
        let indexJ = j + 1;
        if (indexI != indexJ) {
            round2Contribute[indexI][indexJ] = Committee.getRound2Contribution(
                indexJ,
                committees[j].C[0],
                committees[i].C,
                committees[i].f[indexJ]
            );
            committees[i]["round2Contribution"][indexJ] =
                round2Contribute[indexI][indexJ];
        }
    }
}

(BigInt.prototype as any).toJSON = function () {
    return this.toString();
};
writeFileSync(
    join(__dirname, filename),
    JSON.stringify(committees, null, " "),
    { flag: "w" }
);
console.log("DONE");
