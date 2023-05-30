// @ts-ignore
import { babyJub } from "circomlibjs";
import bigInt, { BigInteger, BigNumber } from "big-integer";
import { Utils } from "./utils";

namespace BabyJub {
    export const primeR: BigInteger = bigInt(babyJub.p, 10);
    export const order: BigInteger = bigInt(babyJub.order, 10);
    export const subOrder: BigInteger = bigInt(babyJub.subOrder, 10);

    export function addPoint(
        a: Array<BigInteger>,
        b: Array<BigInteger>
    ): Array<BigInteger> {
        let result = babyJub.addPoint(
            Utils.getBigIntArray(a),
            Utils.getBigIntArray(b)
        );
        return Utils.getBigIntegerArray(result);
    }

    export function mulPointEscalar(e: Array<BigInteger>, scalar: BigInteger) {
        let result = babyJub.mulPointEscalar(
            Utils.getBigIntArray(e),
            scalar.toString(10)
        );
        return Utils.getBigIntegerArray(result);
    }

    export function mulPointBaseScalar(scalar: BigInteger): Array<BigInteger> {
        let result = babyJub.mulPointEscalar(
            babyJub.Base8,
            scalar.toString(10)
        );
        return Utils.getBigIntegerArray(result);
    }

    export function isOnCurve(p: Array<BigInteger>): boolean {
        return babyJub.inCurve(Utils.getBigIntArray(p));
    }

    export function getZeroPoint(): Array<BigInteger> {
        return [bigInt(0), bigInt(1)];
    }

    export function packPoint(point: Array<BigInteger>): Buffer {
        return babyJub.packPoint(Utils.getBigIntArray(point));
    }

    export function unpackPoint(packedPoint: Buffer) {
        return Utils.getBigIntegerArray(
            babyJub.unpackPoint(packedPoint) as Array<BigInt>
        );
    }
}

export default BabyJub;
