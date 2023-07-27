import { Committee, Utils } from "distributed-key-generation";

async function main() {
    let t = 3;
    let n = 5;
    let result = [];
    for (let i = 0; i < n; i++) {
        result.push(Committee.getRandomPolynomial(t, n));
    }
    Utils.logFullObject(result);
}

main().then(() => {});
