// @ts-ignore
import { poseidon } from "circomlibjs";
import bigInt, { BigInteger, BigNumber } from "big-integer";
import { Utils } from "./utils";
import BabyJub from "./babyjub";
import { Element } from "fixed-merkle-tree";

namespace Poseidon {
    export function hashLeftRight(left: Element, right: Element) {
        // let hashFunction = poseidon.createHash();
        return poseidon([left, right]);
    }
}

export default Poseidon;
