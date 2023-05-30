// @ts-ignore
import { pedersenHash } from "circomlibjs";
import bigInt, { BigInteger, BigNumber } from "big-integer";
import {Utils} from "./utils";
import BabyJub from "./babyjub";

namespace Pedersen {
    export function hash(msg: Buffer): BigInteger {
        let hash: Buffer = pedersenHash.hash(msg);
        return BabyJub.unpackPoint(hash)[0];
    }
}

export default Pedersen;
