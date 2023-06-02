import bigInt, { BigInteger, BigNumber } from "big-integer";
import { randomBytes } from "crypto";
import util from "util";

namespace Utils {
    export function getBigInt(n: BigInteger): BigInt {
        return BigInt(n.toString());
    }

    export function getBigIntArray(arr: Array<BigInteger>): Array<BigInt> {
        let result = new Array<BigInt>();
        for (let i = 0; i < arr.length; i++) {
            result.push(getBigInt(arr[i]));
        }
        return result;
    }

    export function getBigInteger(n: BigInt) {
        return bigInt(n.toString(), 10);
    }

    export function getBigIntegerArray(arr: Array<BigInt>): Array<BigInteger> {
        let result = new Array<BigInteger>();
        for (let i = 0; i < arr.length; i++) {
            result.push(getBigInteger(arr[i]));
        }
        return result;
    }

    export function getRandomBytes(n: number): BigInteger {
        const buf = randomBytes(n);
        return bigInt(buf.toString("hex"), 16);
    }

    export function bigIntegerToBuffer(msg: BigInteger, n: number): Buffer {
        let hex = msg.toString(16);
        while (hex.length < n * 2) {
            hex = "0" + hex;
        }
        let tmp = "";
        for (let i = 0; i < n; i++) {
            let start = 2 * n - 2 * (i + 1);
            tmp += hex.slice(start, start + 2);
        }
        return Buffer.from(tmp, "hex");
    }

    export function bufferToBigInteger(buf: Buffer, n: number): BigInteger {
        let hex = bufferToHex(buf);
        while (hex.length < n * 2) {
            hex = "0" + hex;
        }
        let tmp = "";
        for (let i = 0; i < n; i++) {
            let start = 2 * n - 2 * (i + 1);
            tmp += hex.slice(start, start + 2);
        }
        return bigInt(tmp, 16);
    }

    export function hexToBuffer(hex: string) {
        return Buffer.from(hex, "hex");
    }

    export function bufferToHex(buf: Buffer) {
        return buf.toString("hex");
    }

    export function stringifyCircuitInput(circuitInput: any): string {
        (BigInt.prototype as any).toJSON = function () {
            return this.toString();
        };
        return JSON.stringify(circuitInput, null, " ");
    }

    export function bigIntegerToHex32(number: BigInteger): string {
        let str = number.toString(16);
        while (str.length < 64) str = "0" + str;
        return str;
    }

    export function genSolidityProof(
        pi_a: string[],
        pi_b: string[][],
        pi_c: string[]
    ) {
        const flatProof = [
            bigInt(pi_a[0]),
            bigInt(pi_a[1]),
            bigInt(pi_b[0][1]),
            bigInt(pi_b[0][0]),
            bigInt(pi_b[1][1]),
            bigInt(pi_b[1][0]),
            bigInt(pi_c[0]),
            bigInt(pi_c[1]),
        ];

        const proof =
            "0x" + flatProof.map((x) => bigIntegerToHex32(x)).join("");
        return proof;
    }

    export function logFullObject(object: any) {
        console.log(
            util.inspect(object, {
                showHidden: false,
                depth: null,
                colors: true,
            })
        );
    }
}

export { Utils };
