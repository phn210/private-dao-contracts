// @ts-ignore
import { babyJub } from "circomlibjs";
import bigInt, { BigInteger, BigNumber } from "big-integer";
import { randomBytes } from "crypto";
import BabyJub from "./babyjub";
import { Utils } from "./utils";
import Pedersen from "./pedersen-hash";
import { Element } from "fixed-merkle-tree";

namespace Committee {
    function calculatePolynomialValue(
        a: BigInteger[],
        t: number,
        x: number
    ): BigInteger {
        let result = bigInt(0);
        for (let i = 0; i < t; i++) {
            result = result.plus(a[i].multiply(bigInt(x).pow(i)));
        }
        return result.mod(BabyJub.subOrder);
    }

    export function getRandomPolynomial(
        participantIndex: number,
        t: number,
        n: number
    ) {
        let result: {
            C: Array<BigInt[]>;
            a0: BigInt;
            f: any;
            secret: {
                i: number;
                "f(i)": BigInt;
            };
        } = {
            C: new Array<BigInt[]>(),
            a0: 0n,
            f: {},
            secret: { i: 0, "f(i)": 0n },
        };
        let a = new Array<BigInteger>(t);
        for (let i = 0; i < t; i++) {
            a[i] = Utils.getRandomBytes(32).mod(BabyJub.subOrder);
            let Ci: BigInteger[] = BabyJub.mulPointBaseScalar(a[i]);
            result.C.push(Utils.getBigIntArray(Ci));
        }

        result.a0 = Utils.getBigInt(a[0]);

        let f = new Array<BigInteger>(n);
        for (let i = 0; i < n; i++) {
            let x = i + 1;
            f[i] = calculatePolynomialValue(a, t, x);
            if (x != participantIndex) {
                result.f[x] = Utils.getBigInt(f[i]);
            } else {
                result.secret = {
                    i: x,
                    "f(i)": Utils.getBigInt(f[i]),
                };
            }
        }
        return result;
    }

    export function getRound2Contribution(
        receiverIndex: number,
        receiverPublicKey: Array<BigInt>,
        C: Array<BigInt[]>,
        f: BigInt
    ) {
        let encryption = elgamalEncrypt(receiverPublicKey, f);
        let ciphers: Array<BigInt> = [];
        ciphers.push(encryption.share.u[0]);
        ciphers.push(encryption.share.u[1]);
        ciphers.push(encryption.share.c);
        return {
            ciphers: ciphers,
            circuitInput: {
                recipientIndex: receiverIndex,
                recipientPublicKey: receiverPublicKey,
                C: C,
                u: encryption.circuitInput.u,
                c: encryption.circuitInput.c,
                f: f,
                b: encryption.circuitInput.b,
            },
        };
    }

    export function getRound2Contributions(
        recipientIndexes: number[],
        recipientPublicKeys: Array<BigInt[]>,
        f: Array<BigInt>,
        C: Array<BigInt[]>
    ) {
        let ciphers: Array<BigInt[]> = [];
        let u: Array<BigInt[]> = [];
        let c: Array<BigInt> = [];
        let b: Array<BigInt> = [];
        for (let i = 0; i < recipientPublicKeys.length; i++) {
            let encryption = elgamalEncrypt(recipientPublicKeys[i], f[i]);
            ciphers.push([
                encryption.share.u[0],
                encryption.share.u[1],
                encryption.share.c,
            ]);
            u.push(encryption.circuitInput.u);
            c.push(encryption.circuitInput.c);
            b.push(encryption.circuitInput.b);
        }

        return {
            ciphers: ciphers,
            circuitInput: {
                recipientIndexes: recipientIndexes,
                recipientPublicKeys: recipientPublicKeys,
                u: u,
                c: c,
                C: C,
                f: f,
                b: b,
            },
        };
    }

    export function elgamalEncrypt(publicKey: Array<BigInt>, msg: BigInt) {
        let b = Utils.getRandomBytes(32).mod(BabyJub.subOrder);
        let u = BabyJub.mulPointBaseScalar(b);
        let v = BabyJub.mulPointEscalar(Utils.getBigIntegerArray(publicKey), b);
        let k = Pedersen.hash(
            Buffer.concat([
                Utils.bigIntegerToBuffer(u[0], 32),
                Utils.bigIntegerToBuffer(u[1], 32),
                Utils.bigIntegerToBuffer(v[0], 32),
                Utils.bigIntegerToBuffer(v[1], 32),
            ])
        );
        let c = k.xor(Utils.getBigInteger(msg));
        while (c.geq(BabyJub.primeR)) {
            b = Utils.getRandomBytes(32).mod(BabyJub.subOrder);
            u = BabyJub.mulPointBaseScalar(b);
            v = BabyJub.mulPointEscalar(Utils.getBigIntegerArray(publicKey), b);
            k = Pedersen.hash(
                Buffer.concat([
                    Utils.bigIntegerToBuffer(u[0], 32),
                    Utils.bigIntegerToBuffer(u[1], 32),
                    Utils.bigIntegerToBuffer(v[0], 32),
                    Utils.bigIntegerToBuffer(v[1], 32),
                ])
            );
            c = k.xor(Utils.getBigInteger(msg));
        }
        return {
            share: {
                u: Utils.getBigIntArray(u),
                c: Utils.getBigInt(c),
            },
            circuitInput: {
                publicKey: publicKey,
                u: Utils.getBigIntArray(u),
                c: Utils.getBigInt(c),
                m: msg,
                b: Utils.getBigInt(b),
            },
        };
    }

    export function elgamalDecrypt(
        privateKey: BigInt,
        u: Array<BigInt>,
        c: BigInt
    ) {
        let pointU = Utils.getBigIntegerArray(u);
        let v = BabyJub.mulPointEscalar(
            pointU,
            Utils.getBigInteger(privateKey)
        );
        let k = Pedersen.hash(
            Buffer.concat([
                Utils.bigIntegerToBuffer(pointU[0], 32),
                Utils.bigIntegerToBuffer(pointU[1], 32),
                Utils.bigIntegerToBuffer(v[0], 32),
                Utils.bigIntegerToBuffer(v[1], 32),
            ])
        );
        let m = k.xor(Utils.getBigInteger(c));
        return {
            m: Utils.getBigInt(m),
            circuitInput: {
                u: u,
                c: c,
                m: Utils.getBigInt(m),
                privateKey: privateKey,
            },
        };
    }

    export function getPartialSecret(f: Array<BigInt>): BigInt {
        let result = bigInt(0);
        for (let i = 0; i < f.length; i++) {
            result = result.plus(Utils.getBigInteger(f[i]));
        }
        return Utils.getBigInt(result.mod(BabyJub.subOrder));
    }

    export function getPublicKey(C: Array<BigInt[]>): Array<BigInt> {
        let result = BabyJub.getZeroPoint();
        for (let i = 0; i < C.length; i++) {
            result = BabyJub.addPoint(result, Utils.getBigIntegerArray(C[i]));
        }
        return Utils.getBigIntArray(result);
    }

    export function accumulateVote(
        R: Array<Array<BigInt[]>>,
        M: Array<Array<BigInt[]>>,
        votingDimension: number,
        userNumber: number
    ) {
        let sumR = new Array<BigInteger[]>(votingDimension);
        let sumM = new Array<BigInteger[]>(votingDimension);
        for (let i = 0; i < votingDimension; i++) {
            sumR[i] = BabyJub.getZeroPoint();
            sumM[i] = BabyJub.getZeroPoint();
        }

        for (let i = 0; i < userNumber; i++) {
            for (let j = 0; j < votingDimension; j++) {
                sumR[j] = BabyJub.addPoint(
                    sumR[j],
                    Utils.getBigIntegerArray(R[i][j])
                );
                sumM[j] = BabyJub.addPoint(
                    sumM[j],
                    Utils.getBigIntegerArray(M[i][j])
                );
            }
        }

        let result = {
            R: new Array<BigInt[]>(votingDimension),
            M: new Array<BigInt[]>(votingDimension),
        };
        for (let i = 0; i < votingDimension; i++) {
            result.R[i] = Utils.getBigIntArray(sumR[i]);
            result.M[i] = Utils.getBigIntArray(sumM[i]);
        }
        return result;
    }

    export function accumulateFund(
        R: Array<Array<BigInt[]>>,
        M: Array<Array<BigInt[]>>,
        votingDimension: number,
        userNumber: number
    ) {
        let sumR = new Array<BigInteger[]>(votingDimension);
        let sumM = new Array<BigInteger[]>(votingDimension);
        for (let i = 0; i < votingDimension; i++) {
            sumR[i] = BabyJub.getZeroPoint();
            sumM[i] = BabyJub.getZeroPoint();
        }

        for (let i = 0; i < userNumber; i++) {
            for (let j = 0; j < votingDimension; j++) {
                sumR[j] = BabyJub.addPoint(
                    sumR[j],
                    Utils.getBigIntegerArray(R[i][j])
                );
                sumM[j] = BabyJub.addPoint(
                    sumM[j],
                    Utils.getBigIntegerArray(M[i][j])
                );
            }
        }

        let result = {
            R: new Array<BigInt[]>(votingDimension),
            M: new Array<BigInt[]>(votingDimension),
        };
        for (let i = 0; i < votingDimension; i++) {
            result.R[i] = Utils.getBigIntArray(sumR[i]);
            result.M[i] = Utils.getBigIntArray(sumM[i]);
        }
        return result;
    }

    export function getTallyContribution(
        privateKey: BigInt,
        f: BigInt,
        u: Array<BigInt[]>,
        c: Array<BigInt>,
        R: Array<BigInt[]>
    ) {
        let decryptedF = new Array<BigInt>();
        for (let i = 0; i < u.length; i++) {
            let plain = elgamalDecrypt(privateKey, u[i], c[i]);
            decryptedF.push(plain.m);
        }
        let ski = getPartialSecret(decryptedF.concat(f));
        let D = new Array<BigInt[]>(R.length);
        for (let i = 0; i < R.length; i++) {
            let Di = BabyJub.mulPointEscalar(
                Utils.getBigIntegerArray(R[i]),
                Utils.getBigInteger(ski)
            );

            D[i] = Utils.getBigIntArray(Di);
        }

        let result = {
            D: D,
            circuitInput: {
                u: u,
                c: c,
                decryptedF: decryptedF,
                f: f,
                R: R,
                D: D,
                privateKey: privateKey,
                partialSecret: ski,
            },
        };
        return result;
    }

    export function getLagrangeCoefficient(
        listIndex: Array<number>
    ): Array<BigInteger> {
        let threshold = listIndex.length;
        let lagrangeCoefficient = new Array<BigInteger>(threshold);
        for (let i = 0; i < threshold; i++) {
            let indexI = listIndex[i];
            let numerator = bigInt(1);
            let denominator = bigInt(1);
            for (let j = 0; j < threshold; j++) {
                let indexJ = listIndex[j];
                if (indexI != indexJ) {
                    numerator = numerator.multiply(indexJ);
                    denominator = denominator.multiply(indexJ - indexI);
                }
            }

            while (denominator.compareTo(0) < 0) {
                denominator = denominator.plus(BabyJub.subOrder);
            }
            denominator = denominator.modInv(BabyJub.subOrder);
            lagrangeCoefficient[i] = numerator
                .multiply(denominator)
                .mod(BabyJub.subOrder);
        }
        return lagrangeCoefficient;
    }
    export function getResultVector(
        listIndex: Array<number>,
        D: Array<Array<BigInt[]>>,
        M: Array<BigInt[]>
    ): Array<BigInt[]> {
        let lagrangeCoefficient = getLagrangeCoefficient(listIndex);
        let threshold = listIndex.length;
        // for (let i = 1; i <= threshold; i++) {
        //     let indexI = i - 1;
        //     let numerator = bigInt(1);
        //     let denominator = bigInt(1);
        //     for (let j = 1; j <= threshold; j++) {
        //         if (j != i) {
        //             numerator = numerator.multiply(j);
        //             denominator = denominator.multiply(j - i);
        //         }
        //     }
        //     denominator = denominator.modInv(BabyJub.subOrder);
        //     lagrangeCoefficient[indexI] = numerator.multiply(denominator);
        //     while (lagrangeCoefficient[indexI].compareTo(0) < 0) {
        //         lagrangeCoefficient[indexI] = lagrangeCoefficient[indexI].plus(
        //             BabyJub.subOrder
        //         );
        //     }
        // }
        // console.log(lagrangeCoefficient);
        let sumD = Array<BigInteger[]>(M.length);
        for (let i = 0; i < sumD.length; i++) {
            sumD[i] = BabyJub.getZeroPoint();
        }
        for (let i = 0; i < threshold; i++) {
            for (let j = 0; j < sumD.length; j++) {
                sumD[j] = BabyJub.addPoint(
                    sumD[j],
                    BabyJub.mulPointEscalar(
                        Utils.getBigIntegerArray(D[i][j]),
                        lagrangeCoefficient[i]
                    )
                );
            }
        }
        // console.log(sumD);
        for (let i = 0; i < sumD.length; i++) {
            // sumD[i] = BabyJub.mulPointEscalar(
            //     sumD[i],
            //     BabyJub.subOrder.minus(1)
            // );
            sumD[i][0] = BabyJub.primeR.minus(sumD[i][0]);
        }

        let result = Array<BigInt[]>(M.length);
        for (let i = 0; i < result.length; i++) {
            result[i] = Utils.getBigIntArray(
                BabyJub.addPoint(Utils.getBigIntegerArray(M[i]), sumD[i])
            );
        }

        return result;
    }
}

namespace Voter {
    export function getVote(
        publicKey: Array<BigInt>,
        idDAO: BigInt,
        idProposal: BigInt,
        votingVector: Array<number>,
        votingPower: BigInt,
        nullifier: BigInt,
        pathElements: Element[],
        pathIndices: number[],
        pathRoot: Element
    ) {
        let dim = votingVector.length;
        let randomVector = new Array<BigInteger>(dim);
        let R = new Array<BigInteger[]>(dim);
        let M = new Array<BigInteger[]>(dim);

        let result = {
            publicKey: publicKey,
            vi: votingPower,
            ri: new Array<BigInt>(),
            Ri: new Array<BigInt[]>(),
            Mi: new Array<BigInt[]>(),
            circuitInput: {
                publicKey: publicKey,
                idDAO: idDAO,
                idProposal: idProposal,
                nullifier: nullifier,
                pathElements: pathElements,
                pathIndices: pathIndices,
                pathRoot: pathRoot,
                nullifierHash: Utils.getBigInt(
                    Pedersen.hash(
                        Buffer.concat([
                            Utils.bigIntegerToBuffer(
                                Utils.getBigInteger(nullifier),
                                32
                            ),
                            Utils.bigIntegerToBuffer(
                                Utils.getBigInteger(idProposal),
                                32
                            ),
                        ])
                    )
                ),
                R: new Array<BigInt[]>(),
                M: new Array<BigInt[]>(),
                r: new Array<BigInt>(),
                votingPower: votingPower,
                o: votingVector,
            },
        };

        for (let i = 0; i < dim; i++) {
            randomVector[i] = Utils.getRandomBytes(32).mod(BabyJub.subOrder);
            R[i] = BabyJub.mulPointBaseScalar(randomVector[i]);

            if (votingVector[i] == 1) {
                M[i] = BabyJub.addPoint(
                    BabyJub.mulPointBaseScalar(
                        Utils.getBigInteger(votingPower)
                    ),
                    BabyJub.mulPointEscalar(
                        Utils.getBigIntegerArray(publicKey),
                        randomVector[i]
                    )
                );
            } else {
                M[i] = BabyJub.addPoint(
                    BabyJub.mulPointBaseScalar(bigInt(0)),
                    BabyJub.mulPointEscalar(
                        Utils.getBigIntegerArray(publicKey),
                        randomVector[i]
                    )
                );
            }

            result.ri.push(Utils.getBigInt(randomVector[i]));
            result.Ri.push(Utils.getBigIntArray(R[i]));
            result.Mi.push(Utils.getBigIntArray(M[i]));
        }

        result.circuitInput.R = result.Ri;
        result.circuitInput.M = result.Mi;
        result.circuitInput.r = result.ri;
        return result;
    }

    export function getFund(
        publicKey: Array<BigInt>,
        idDAO: Array<BigInt>,
        votingPower: BigInt,
        votingVector: Array<number>
    ) {
        let dim = idDAO.length;
        let randomVector = new Array<BigInteger>(dim);
        let R = new Array<BigInteger[]>(dim);
        let M = new Array<BigInteger[]>(dim);

        let result = {
            publicKey: publicKey,
            vi: votingPower,
            ri: new Array<BigInt>(),
            Ri: new Array<BigInt[]>(),
            Mi: new Array<BigInt[]>(),
            commitment: Utils.getBigInt(bigInt(0)),
            circuitInput: {
                publicKey: publicKey,
                idDAO: idDAO,
                votingPower: votingPower,
                commitment: Utils.getBigInt(bigInt(0)),
                R: new Array<BigInt[]>(),
                M: new Array<BigInt[]>(),
                nullifier: Utils.getBigInt(bigInt(0)),
                r: new Array<BigInt>(),
                o: votingVector,
            },
        };

        let id = bigInt(0);

        for (let i = 0; i < dim; i++) {
            id = id.plus(
                Utils.getBigInteger(idDAO[i]).multiply(votingVector[i])
            );
            randomVector[i] = Utils.getRandomBytes(32).mod(BabyJub.subOrder);
            R[i] = BabyJub.mulPointBaseScalar(randomVector[i]);

            if (votingVector[i] == 1) {
                M[i] = BabyJub.addPoint(
                    BabyJub.mulPointBaseScalar(
                        Utils.getBigInteger(votingPower)
                    ),
                    BabyJub.mulPointEscalar(
                        Utils.getBigIntegerArray(publicKey),
                        randomVector[i]
                    )
                );
            } else {
                M[i] = BabyJub.addPoint(
                    BabyJub.mulPointBaseScalar(bigInt(0)),
                    BabyJub.mulPointEscalar(
                        Utils.getBigIntegerArray(publicKey),
                        randomVector[i]
                    )
                );
            }

            result.ri.push(Utils.getBigInt(randomVector[i]));
            result.Ri.push(Utils.getBigIntArray(R[i]));
            result.Mi.push(Utils.getBigIntArray(M[i]));
        }

        let nullifier = Utils.getRandomBytes(32).mod(BabyJub.primeR);
        let commitment = Pedersen.hash(
            Buffer.concat([
                Utils.bigIntegerToBuffer(nullifier, 32),
                Utils.bigIntegerToBuffer(id, 32),
                Utils.bigIntegerToBuffer(Utils.getBigInteger(votingPower), 32),
            ])
        ).mod(BabyJub.primeR);
        result.commitment = Utils.getBigInt(commitment);
        result.circuitInput.commitment = Utils.getBigInt(commitment);
        result.circuitInput.R = result.Ri;
        result.circuitInput.M = result.Mi;
        result.circuitInput.nullifier = Utils.getBigInt(nullifier);
        result.circuitInput.r = result.ri;
        return result;
    }
}

export { Committee, Voter };
