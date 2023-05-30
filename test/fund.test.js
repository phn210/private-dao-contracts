const { expect } = require("chai");
const { ethers } = require("hardhat");
const genPoseidonP2Contract = require("circomlibjs/src/poseidon_gencontract");
const snarkjs = require("snarkjs");
const { Committee, Voter } = require("../libs/index");
const { Utils } = require("../libs/utils");
const Tree = require("../libs/merkle-tree");
const { VoterData, CommitteeData } = require("./data");

var t = 3;
var n = 5;
var votersLength = VoterData.data1.votingPower.length;
describe("Test FundManager", () => {
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

        let merkleTreeConfig = [32, this.poseidon.address];
        let fundingRoundConfig = [10, 10, 10];
        let dkgConfig = [
            this.round2ContributionVerifier.address,
            this.fundingVerifierDim3.address,
            this.votingVerifierDim3.address,
            this.tallyContributionVerifierDim3.address,
            this.resultVerifierDim3.address,
        ];

        let FundManager = await ethers.getContractFactory(
            "FundManager",
            this.founder
        );
        this.fundManager = await FundManager.deploy(
            committeeList,
            0,
            merkleTreeConfig,
            fundingRoundConfig,
            dkgConfig
        );
        this.dkgContract = await ethers.getContractAt(
            "DKG",
            await this.fundManager.dkgContract()
        );
    });
    it("Generate Funding Distributed Key", async () => {
        // Generate key
        await this.dkgContract.generateDistributedKey(3, 0);
        expect(await this.dkgContract.distributedKeyCounter()).to.be.equal(1);
        let keyID = 0;
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
            let ciphers = [];
            let proofs = [];

            for (let j = 0; j < round1DataSubmissions.length; j++) {
                let round1DataSubmission = round1DataSubmissions[j];
                let recipientIndex = round1DataSubmission.senderIndex;
                if (recipientIndex != senderIndex) {
                    recipientIndexes.push(recipientIndex);
                    let recipientPublicKeyX = BigInt(round1DataSubmission.x[0]);
                    let recipientPublicKeyY = BigInt(round1DataSubmission.y[0]);
                    let round2Contribution = Committee.getRound2Contribution(
                        recipientIndex,
                        [recipientPublicKeyX, recipientPublicKeyY],
                        CommitteeData.data1[i].C,
                        CommitteeData.data1[i].f[recipientIndex]
                    );
                    ciphers.push([
                        round2Contribution.share.u[0],
                        round2Contribution.share.u[1],
                        round2Contribution.share.c,
                    ]);
                    let { proof, publicSignals } =
                        await snarkjs.groth16.fullProve(
                            round2Contribution.circuitInput,
                            __dirname +
                                "/../zk-resources/wasm/round-2-contribution.wasm",
                            __dirname +
                                "/../zk-resources/zkey/round-2-contribution_final.zkey"
                        );
                    proof = Utils.genSolidityProof(
                        proof.pi_a,
                        proof.pi_b,
                        proof.pi_c
                    );
                    proofs.push(proof);
                }
            }
            await this.dkgContract
                .connect(this.committees[i])
                .submitRound2Contribution(keyID, [
                    senderIndex,
                    recipientIndexes,
                    ciphers,
                    proofs,
                ]);
        }
        expect(
            await this.dkgContract.getDistributedKeyState(keyID)
        ).to.be.equal(2);
    });
    it("Generate Voting Distributed Key", async () => {
        // Generate key
        await this.dkgContract.generateDistributedKey(3, 1);
        expect(await this.dkgContract.distributedKeyCounter()).to.be.equal(2);
        let keyID = 1;
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
            let ciphers = [];
            let proofs = [];

            for (let j = 0; j < round1DataSubmissions.length; j++) {
                let round1DataSubmission = round1DataSubmissions[j];
                let recipientIndex = round1DataSubmission.senderIndex;
                if (recipientIndex != senderIndex) {
                    recipientIndexes.push(recipientIndex);
                    let recipientPublicKeyX = BigInt(round1DataSubmission.x[0]);
                    let recipientPublicKeyY = BigInt(round1DataSubmission.y[0]);
                    let round2Contribution = Committee.getRound2Contribution(
                        recipientIndex,
                        [recipientPublicKeyX, recipientPublicKeyY],
                        CommitteeData.data1[i].C,
                        CommitteeData.data1[i].f[recipientIndex]
                    );
                    ciphers.push([
                        round2Contribution.share.u[0],
                        round2Contribution.share.u[1],
                        round2Contribution.share.c,
                    ]);
                    let { proof, publicSignals } =
                        await snarkjs.groth16.fullProve(
                            round2Contribution.circuitInput,
                            __dirname +
                                "/../zk-resources/wasm/round-2-contribution.wasm",
                            __dirname +
                                "/../zk-resources/zkey/round-2-contribution_final.zkey"
                        );
                    proof = Utils.genSolidityProof(
                        proof.pi_a,
                        proof.pi_b,
                        proof.pi_c
                    );
                    proofs.push(proof);
                }
            }
            await this.dkgContract
                .connect(this.committees[i])
                .submitRound2Contribution(keyID, [
                    senderIndex,
                    recipientIndexes,
                    ciphers,
                    proofs,
                ]);
        }
        expect(
            await this.dkgContract.getDistributedKeyState(keyID)
        ).to.be.equal(2);
        this.round2ContributionVerifier.
    });


});
