// @ts-ignore
import { mimcsponge } from "circomlibjs";
import { Element } from "fixed-merkle-tree";
import bigInt, { BigInteger, BigNumber } from "big-integer";

namespace MiMC {
    export function hashLeftRight(left: Element, right: Element) {
        return mimcsponge.multiHash([left, right]).toString();
    }
}

export default MiMC;
