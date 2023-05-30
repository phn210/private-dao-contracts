// @ts-ignore
import { poseidon } from "circomlibjs";
import bigInt, { BigInteger, BigNumber } from "big-integer";
import { Utils } from "./utils";
import BabyJub from "./babyjub";
import { Element } from "fixed-merkle-tree";

namespace Poseidon {
    export function hashLeftRight(left: Element, right: Element) {
        // let nRoundsF = 8;
        // let nRoundsPArr = [
        //     56, 57, 56, 60, 60, 63, 64, 63, 60, 66, 60, 65, 70, 60, 64, 68
        // ];
        // let nInputs = 2;
        // let t = nInputs + 1;
        // let nRoundsP = nRoundsPArr[t - 2];
        let hashFunction = poseidon.createHash();
        return hashFunction([left, right]);
    }
}

export default Poseidon;
