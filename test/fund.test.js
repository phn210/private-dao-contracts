const { expect } = require("chai");
const { ethers } = require("hardhat");
const genPoseidonP2Contract = require("circomlibjs/src/poseidon_gencontract");
const snarkjs = require("snarkjs");
const { Committee, Voter } = require("../libs/index");
const { Utils } = require("../libs/utils");
const Tree = require("../libs/merkle-tree");
const { VoterData, CommitteeData } = require("./data");
const { utils } = require("mocha");

var dim = 3;
var t = 3;
var n = 5;
var votersLength = VoterData.data1.votingPower.length;
describe("Test Funding Flow", () => {
    before(async () => {
        let accounts = await ethers.getSigners();
        this.founder = accounts[0];
        this.committees = [];
        this.daos = [];
        this.voters = [];
        let committeeList = [];
        for (let i = 0; i < n; i++) {
            this.committees.push(accounts[1 + i]);
            committeeList.push(accounts[1 + i].address);
        }
        for (let i = 0; i < votersLength; i++) {
            this.voters.push(accounts[1 + n + i]);
        }
        for (let i = 0; i < 3; i++) {
            this.daos.push(accounts[1 + n + votersLength + i]);
        }

        let Round2ContributionVerifier = await ethers.getContractFactory(
            "Round2ContributionVerifier",
            this.founder
        );
        this.round2ContributionVerifier =
            await Round2ContributionVerifier.deploy();

        let FundingVerifierDim3 = await ethers.getContractFactory(
            "FundingVerifierDim3",
            this.founder
        );
        this.fundingVerifierDim3 = await FundingVerifierDim3.deploy();

        let VotingVerifierDim3 = await ethers.getContractFactory(
            "VotingVerifierDim3",
            this.founder
        );
        this.votingVerifierDim3 = await VotingVerifierDim3.deploy();

        let TallyContributionVerifierDim3 = await ethers.getContractFactory(
            "TallyContributionVerifierDim3",
            this.founder
        );
        this.tallyContributionVerifierDim3 =
            await TallyContributionVerifierDim3.deploy();

        let ResultVerifierDim3 = await ethers.getContractFactory(
            "ResultVerifierDim3",
            this.founder
        );
        this.resultVerifierDim3 = await ResultVerifierDim3.deploy();
        let PoseidonUnit2 = await ethers.getContractFactory(
            genPoseidonP2Contract.abi,
            genPoseidonP2Contract.createCode(),
            this.founder
        );
        let poseidonUnit2 = await PoseidonUnit2.deploy();
        await poseidonUnit2.deployed();
        let Poseidon = await ethers.getContractFactory(
            "Poseidon",
            this.founder
        );
        this.poseidon = await Poseidon.deploy(poseidonUnit2.address);
        await this.poseidon.deployed();

        let merkleTreeConfig = [20, this.poseidon.address];
        let fundingRoundConfig = [50, 50, 50];
        let dkgConfig = [
            this.round2ContributionVerifier.address,
            this.fundingVerifierDim3.address,
            this.votingVerifierDim3.address,
            this.tallyContributionVerifierDim3.address,
            this.resultVerifierDim3.address,
        ];

        let DAOManager = await ethers.getContractFactory(
            "DAOManager",
            this.founder
        );

        this.daoManager = await DAOManager.deploy();

        let FundManager = await ethers.getContractFactory(
            "FundManager",
            this.founder
        );
        mineBlocks(1);
        this.fundManager = await FundManager.deploy(
            committeeList,
            this.daoManager.address,
            0,
            merkleTreeConfig,
            fundingRoundConfig,
            dkgConfig,
            { gasLimit: 300000000 }
        );
        this.dkgContract = await ethers.getContractAt(
            "DKG",
            await this.fundManager.dkgContract()
        );

        await this.daoManager.setFundManager(this.fundManager.address);
        await this.daoManager.setDKG(this.dkgContract.address);
    });
    describe("Test DKG", (async) => {
        it("Generate Funding Distributed Key", async () => {
            // Generate key
            let keyID = await this.dkgContract.distributedKeyCounter();
            await this.dkgContract.generateDistributedKey(3, 0);
            expect(await this.dkgContract.distributedKeyCounter()).to.be.equal(
                Number(keyID) + 1
            );

            expect(
                await this.dkgContract.getDistributedKeyState(keyID)
            ).to.be.equal(0);

            // Submit round 1
            for (let i = 0; i < this.committees.length; i++) {
                let x = [];
                let y = [];
                for (let j = 0; j < t; j++) {
                    x.push(CommitteeData.data1[i].C[j][0]);
                    y.push(CommitteeData.data1[i].C[j][1]);
                }
                await this.dkgContract
                    .connect(this.committees[i])
                    .submitRound1Contribution(keyID, [x, y]);
            }
            expect(
                await this.dkgContract.getDistributedKeyState(keyID)
            ).to.be.equal(1);

            // Submit round 2
            let listCommitteeIndex = [];
            for (let i = 0; i < this.committees.length; i++) {
                listCommitteeIndex.push(i + 1);
            }
            let round1DataSubmissions =
                await this.dkgContract.getRound1DataSubmissions(keyID);
            for (let i = 0; i < this.committees.length; i++) {
                let senderIndex = await this.dkgContract.getCommitteeIndex(
                    this.committees[i].address,
                    keyID
                );
                let recipientIndexes = [];
                let recipientPublicKeys = [];
                let f = [];

                for (let j = 0; j < round1DataSubmissions.length; j++) {
                    let round1DataSubmission = round1DataSubmissions[j];
                    let recipientIndex = round1DataSubmission.senderIndex;
                    if (recipientIndex != senderIndex) {
                        recipientIndexes.push(recipientIndex);
                        let recipientPublicKeyX = BigInt(
                            round1DataSubmission.x[0]
                        );
                        let recipientPublicKeyY = BigInt(
                            round1DataSubmission.y[0]
                        );
                        recipientPublicKeys.push([
                            recipientPublicKeyX,
                            recipientPublicKeyY,
                        ]);
                        f.push(CommitteeData.data1[i].f[recipientIndex]);
                    }
                }
                let round2Contribution = Committee.getRound2Contributions(
                    recipientIndexes,
                    recipientPublicKeys,
                    f,
                    CommitteeData.data1[i].C
                );
                let ciphers = round2Contribution.ciphers;
                let { proof, publicSignals } = await snarkjs.groth16.fullProve(
                    round2Contribution.circuitInput,
                    __dirname +
                        "/../zk-resources/wasm/round-2-contribution.wasm",
                    __dirname +
                        "/../zk-resources/zkey/round-2-contribution_final.zkey"
                );
                proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
                await this.dkgContract
                    .connect(this.committees[i])
                    .submitRound2Contribution(keyID, [
                        senderIndex,
                        recipientIndexes,
                        ciphers,
                        proof,
                    ]);
            }
            expect(
                await this.dkgContract.getDistributedKeyState(keyID)
            ).to.be.equal(2);

            // for (let i = 1; i <= n; i++) {
            //     console.log(
            //         await this.dkgContract.getRound2DataSubmissions(keyID, i)
            //     );
            // }
        });

        //     it("Generate Voting Distributed Key", async () => {
        //         // Generate key
        //         let keyID = await this.dkgContract.distributedKeyCounter();
        //         await this.dkgContract.generateDistributedKey(3, 0);
        //         expect(await this.dkgContract.distributedKeyCounter()).to.be.equal(
        //             Number(keyID) + 1
        //         );
        //         expect(
        //             await this.dkgContract.getDistributedKeyState(keyID)
        //         ).to.be.equal(0);

        //         // Submit round 1
        //         for (let i = 0; i < this.committees.length; i++) {
        //             let x = [];
        //             let y = [];
        //             for (let j = 0; j < t; j++) {
        //                 x.push(CommitteeData.data1[i].C[j][0]);
        //                 y.push(CommitteeData.data1[i].C[j][1]);
        //             }
        //             await this.dkgContract
        //                 .connect(this.committees[i])
        //                 .submitRound1Contribution(keyID, [x, y]);
        //         }
        //         expect(
        //             await this.dkgContract.getDistributedKeyState(keyID)
        //         ).to.be.equal(1);

        //         // Submit round 2
        //         let listCommitteeIndex = [];
        //         for (let i = 0; i < this.committees.length; i++) {
        //             listCommitteeIndex.push(i + 1);
        //         }
        //         let round1DataSubmissions =
        //             await this.dkgContract.getRound1DataSubmissions(keyID);
        //         for (let i = 0; i < this.committees.length; i++) {
        //             let senderIndex = await this.dkgContract.getCommitteeIndex(
        //                 this.committees[i].address,
        //                 keyID
        //             );
        //             let recipientIndexes = [];
        //             let ciphers = [];
        //             let proofs = [];

        //             for (let j = 0; j < round1DataSubmissions.length; j++) {
        //                 let round1DataSubmission = round1DataSubmissions[j];
        //                 let recipientIndex = round1DataSubmission.senderIndex;
        //                 if (recipientIndex != senderIndex) {
        //                     recipientIndexes.push(recipientIndex);
        //                     let recipientPublicKeyX = BigInt(
        //                         round1DataSubmission.x[0]
        //                     );
        //                     let recipientPublicKeyY = BigInt(
        //                         round1DataSubmission.y[0]
        //                     );
        //                     let round2Contribution =
        //                         Committee.getRound2Contribution(
        //                             recipientIndex,
        //                             [recipientPublicKeyX, recipientPublicKeyY],
        //                             CommitteeData.data1[i].C,
        //                             CommitteeData.data1[i].f[recipientIndex]
        //                         );
        //                     ciphers.push([
        //                         round2Contribution.share.u[0],
        //                         round2Contribution.share.u[1],
        //                         round2Contribution.share.c,
        //                     ]);
        //                     let { proof, publicSignals } =
        //                         await snarkjs.groth16.fullProve(
        //                             round2Contribution.circuitInput,
        //                             __dirname +
        //                                 "/../zk-resources/wasm/round-2-contribution.wasm",
        //                             __dirname +
        //                                 "/../zk-resources/zkey/round-2-contribution_final.zkey"
        //                         );
        //                     proof = Utils.genSolidityProof(
        //                         proof.pi_a,
        //                         proof.pi_b,
        //                         proof.pi_c
        //                     );
        //                     proofs.push(proof);
        //                 }
        //             }
        //             await this.dkgContract
        //                 .connect(this.committees[i])
        //                 .submitRound2Contribution(keyID, [
        //                     senderIndex,
        //                     recipientIndexes,
        //                     ciphers,
        //                     proofs,
        //                 ]);
        //         }
        //         expect(
        //             await this.dkgContract.getDistributedKeyState(keyID)
        //         ).to.be.equal(2);
        //     });
    });
    describe("Test FundManager", async () => {
        it("Success Flow", async () => {
            let keyID = 0; // Funding key
            for (let i = 0; i < this.daos.length; i++) {
                await this.fundManager.connect(this.daos[i]).applyForFunding();
            }
            expect(
                await this.fundManager.getFundingRoundQueueLength()
            ).to.be.equal(this.daos.length);

            await this.fundManager.launchFundingRound(keyID);
            expect(await this.fundManager.fundingRoundInProgress()).to.be.true;
            let fundingRoundID = 0;

            // Mine block to Active phase
            expect(
                await this.fundManager.getFundingRoundState(fundingRoundID)
            ).to.be.equal(0);
            await mineBlocks(51);
            expect(
                await this.fundManager.getFundingRoundState(fundingRoundID)
            ).to.be.equal(1);
            // let publicKeyX, publicKeyY;
            let [publicKeyX, publicKeyY] = await this.dkgContract.getPublicKey(
                keyID
            );
            publicKeyX = BigInt(publicKeyX);
            publicKeyY = BigInt(publicKeyY);

            let tmp = await this.fundManager.getListDAO(fundingRoundID);
            let listDAO = [];
            for (let i = 0; i < tmp.length; i++) {
                listDAO.push(BigInt(tmp[i]));
            }
            for (let i = 0; i < this.voters.length; i++) {
                let fund = Voter.getFund(
                    [publicKeyX, publicKeyY],
                    listDAO,
                    VoterData.data1.votingPower[i],
                    VoterData.data1.fundingVector[i]
                );
                // console.log(fund);
                let { proof, publicSignals } = await snarkjs.groth16.fullProve(
                    fund.circuitInput,
                    __dirname + "/../zk-resources/wasm/fund_dim3.wasm",
                    __dirname + "/../zk-resources/zkey/fund_dim3_final.zkey"
                );
                proof = Utils.genSolidityProof(
                    proof.pi_a,
                    proof.pi_b,
                    proof.pi_c
                );
                await this.fundManager
                    .connect(this.voters[i])
                    .fund(
                        fundingRoundID,
                        fund.commitment,
                        fund.Ri,
                        fund.Mi,
                        proof,
                        { value: VoterData.data1.votingPower[i] }
                    );
            }

            await mineBlocks(51);
            expect(
                await this.fundManager.getFundingRoundState(fundingRoundID)
            ).to.be.equal(2);
            await this.fundManager.startTallying(fundingRoundID);

            let requestID = await this.fundManager.getRequestID(
                keyID,
                this.fundManager.address,
                fundingRoundID
            );
            tmp = await this.dkgContract.getR(requestID);
            let R = [];
            for (let i = 0; i < tmp.length; i++) {
                R.push([BigInt(tmp[i][0]), BigInt(tmp[i][1])]);
            }

            for (let i = 0; i < t; i++) {
                let recipientIndex = i + 1;
                let round2DataSubmissions =
                    await this.dkgContract.getRound2DataSubmissions(
                        keyID,
                        recipientIndex
                    );

                // console.log(recipientIndex, round2DataSubmissions);
                let senderIndexes = [];
                let u = [];
                let c = [];
                for (let j = 0; j < round2DataSubmissions.length; j++) {
                    senderIndexes.push(round2DataSubmissions[j].senderIndex);
                    u.push([
                        BigInt(round2DataSubmissions[j].ciphers[0]),
                        BigInt(round2DataSubmissions[j].ciphers[1]),
                    ]);
                    c.push(BigInt(round2DataSubmissions[j].ciphers[2]));
                }

                let tallyContribution = Committee.getTallyContribution(
                    CommitteeData.data1[i].a0,
                    CommitteeData.data1[i].secret["f(i)"],
                    u,
                    c,
                    R
                );
                // console.log(tallyContribution);
                let { proof, publicSignals } = await snarkjs.groth16.fullProve(
                    tallyContribution.circuitInput,
                    __dirname +
                        "/../zk-resources/wasm/tally-contribution_dim3.wasm",
                    __dirname +
                        "/../zk-resources/zkey/tally-contribution_dim3_final.zkey"
                );
                proof = Utils.genSolidityProof(
                    proof.pi_a,
                    proof.pi_b,
                    proof.pi_c
                );
                // console.log(proof);
                await this.dkgContract
                    .connect(this.committees[i])
                    .submitTallyContribution(requestID, [
                        recipientIndex,
                        tallyContribution.D,
                        proof,
                    ]);
            }

            let tallyDataSubmissions =
                await this.dkgContract.getTallyDataSubmissions(requestID);
            tmp = await this.dkgContract.getM(requestID);
            let listIndex = [];
            let D = [];
            let M = [];

            for (let i = 0; i < tallyDataSubmissions.length; i++) {
                let tallyDataSubmission = tallyDataSubmissions[i];
                listIndex.push(Number(tallyDataSubmission.senderIndex));
                D[i] = [];
                for (let j = 0; j < dim; j++) {
                    D[i].push([
                        BigInt(tallyDataSubmission.Di[j][0]),
                        BigInt(tallyDataSubmission.Di[j][1]),
                    ]);
                }
            }

            for (let i = 0; i < dim; i++) {
                M.push([BigInt(tmp[i][0]), BigInt(tmp[i][1])]);
            }

            let resultVector = Committee.getResultVector(listIndex, D, M);
            // console.log(resultVector);

            // Should brute-force resultVector to get result
            let result = [0n, 0n, 0n];
            for (let i = 0; i < VoterData.data1.fundingVector.length; i++) {
                let fundingVector = VoterData.data1.fundingVector[i];
                for (let j = 0; j < fundingVector.length; j++) {
                    result[j] +=
                        VoterData.data1.votingPower[i] *
                        BigInt(fundingVector[j]);
                }
            }
            // console.log(result);
            let { proof, publicSignals } = await snarkjs.groth16.fullProve(
                { listIndex: listIndex, D: D, M: M, result: result },
                __dirname + "/../zk-resources/wasm/result-verifier_dim3.wasm",
                __dirname +
                    "/../zk-resources/zkey/result-verifier_dim3_final.zkey"
            );
            proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
            // console.log(proof);
            await this.dkgContract.submitTallyResult(requestID, result, proof);
            expect(
                await this.fundManager.getFundingRoundState(fundingRoundID)
            ).to.be.equal(3);

            await this.fundManager.finalizeFundingRound(fundingRoundID);
            expect(
                await this.fundManager.getFundingRoundState(fundingRoundID)
            ).to.be.equal(4);

            // Withdraw fund to DAO
            for (let i = 0; i < result.length; i++) {
                let balanceBefore = await ethers.provider.getBalance(
                    this.daos[i].address
                );
                await this.fundManager.withdrawFund(
                    fundingRoundID,
                    this.daos[i].address
                );
                let balanceAfter = await ethers.provider.getBalance(
                    this.daos[i].address
                );
                expect(BigInt(balanceBefore) + result[i]).to.be.equal(
                    BigInt(balanceAfter)
                );
            }
        });
    });
});

async function bn() {
    let _bn = await ethers.provider.getBlockNumber();
    // console.log("\x1b[33m%s\x1b[0m", "Block =", _bn.toString());
    return _bn;
}

async function moveTimestamp(seconds) {
    // console.log(`Skipping ${seconds} seconds...`);
    // console.log("Timestamp before:", await ts());
    await ethers.provider.send("evm_increaseTime", [seconds]);
    await ethers.provider.send("evm_mine", []);
    // console.log("Timestamp after:", await ts());
}

async function mineBlocks(nums) {
    // console.log(`Skipping ${nums} blocks...`);
    console.log("Block before:", await bn());
    for (let i = 0; i < nums; i++) await ethers.provider.send("evm_mine", []);
    console.log("Block after:", await bn());
}
