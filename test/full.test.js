const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const genPoseidonContract = require("circomlibjs/src/poseidon_gencontract");
const snarkjs = require("snarkjs");
const { Committee, Voter } = require("../libs/index");
const { Utils } = require("../libs/utils");
const { Tree } = require("../libs/merkle-tree");
const { VoterData, CommitteeData } = require("./data");
const psd = require("../libs/poseidon-hash");

var dim = 3;
var t = 3;
var n = 5;
var votersLength = VoterData.data1.votingPower.length;
describe("Test DAO Flows", () => {
    before(async () => {
        let accounts = await ethers.getSigners();
        this.founder = accounts[0];
        this.committees = [];
        this.daos = [];
        this.voters = [];
        let committeeList = [];
        this.fundingKeyId = "";
        this.votingKeyId = "";
        this.tree = Tree.getPoseidonHashTree(20);
        this.commitments = [];
        this.votingNullifiers = [];

        for (let i = 0; i < n; i++) {
            this.committees.push(accounts[1 + i]);
            committeeList.push(accounts[1 + i].address);
        }
        for (let i = 0; i < votersLength; i++) {
            this.voters.push(accounts[1 + n + i]);
        }
        // for (let i = 0; i < 3; i++) {
        //     this.daos.push(accounts[1 + n + votersLength + i]);
        // }

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
            genPoseidonContract.abi,
            genPoseidonContract.createCode(2),
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

        this.daoConfig = [50, 50, 50, 50, 50];
        let DAOManager = await ethers.getContractFactory(
            "DAOManager",
            this.founder
        );

        this.requiredDeposit = 0;
        this.daoManager = await DAOManager.deploy(this.requiredDeposit);

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

        console.log("DKG ", this.dkgContract.address);
        console.log("FundManager ", this.fundManager.address);
        console.log("DAOManager ", this.daoManager.address);
    });

    describe("Test DKG", async () => {
        it("Generate Funding Distributed Key", async () => {
            let keyID = await this.dkgContract.distributedKeyCounter();
            this.fundingKeyId = keyID;
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
                proof = Utils.genSolidityProof(
                    proof.pi_a,
                    proof.pi_b,
                    proof.pi_c
                );
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
        });

        it("Generate Voting Distributed Key", async () => {
            let keyID = await this.dkgContract.distributedKeyCounter();
            this.votingKeyId = keyID;
            await this.dkgContract.generateDistributedKey(3, 1);
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
                proof = Utils.genSolidityProof(
                    proof.pi_a,
                    proof.pi_b,
                    proof.pi_c
                );
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
        });
    });

    describe("Test DAOManager", async () => {
        it("Success Flow", async () => {
            await this.daoManager.setDistributedKeyID(this.votingKeyId);
            expect(await this.daoManager.distributedKeyID()).to.be.eq(
                this.votingKeyId
            );

            for (let i = 0; i < 3; i++) {
                let expectedId = await this.daoManager.daoCounter();
                await this.daoManager.createDAO(
                    expectedId,
                    this.daoConfig,
                    "0x1d395c3cb1e6c1e9d9ad3eb571322666a8f5d45c99b67684a44c3a2b1ccda8fe"
                );
                this.daos.push(await this.daoManager.daos(i));
            }

            expect(await this.daoManager.daoCounter()).to.be.eq(3);
        });
    });

    describe("Test FundManager", async () => {
        it("Success Flow", async () => {
            let keyID = this.fundingKeyId;
            expect(
                await this.fundManager.getFundingRoundQueueLength()
            ).to.be.equal(3);

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
                        {
                            value: VoterData.data1.votingPower[i],
                        }
                    );
                // console.log(fund.circuitInput.commitment.toString());
                this.tree.insert(fund.circuitInput.commitment.toString());
                this.commitments.push(fund.circuitInput.commitment.toString());
                this.votingNullifiers.push(fund.circuitInput.nullifier);
            }
            console.log("Root:", this.tree.root);
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
                    recipientIndex,
                    CommitteeData.data1[i].C,
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
            // console.log(requestID);
            // console.log(await this.dkgContract.tallyTrackers(requestID));
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
            expect(await this.fundManager.getLastRoot()).to.be.eq(
                this.tree.root
            );

            // Withdraw fund to DAO
            for (let i = 0; i < result.length; i++) {
                let balanceBefore = await ethers.provider.getBalance(
                    this.daos[i]
                );
                await this.fundManager.withdrawFund(
                    fundingRoundID,
                    this.daos[i]
                );
                let balanceAfter = await ethers.provider.getBalance(
                    this.daos[i]
                );
                expect(BigInt(balanceBefore) + result[i]).to.be.equal(
                    BigInt(balanceAfter)
                );
            }
        });
    });

    describe("Test DAO", async () => {
        it("Success Flow", async () => {
            let keyID = this.votingKeyId;
            this.firstDAO = await ethers.getContractAt(
                "DAO",
                this.daos[0],
                this.founder
            );
            // console.log(this.firstDAO);

            expect(this.firstDAO.address).to.be.eq(this.daos[0]);

            let MockContract = await ethers.getContractFactory(
                "Mock",
                this.founder
            );
            this.mock = await MockContract.deploy(this.firstDAO.address);

            let firstProposal = {
                shortDes: "Test ZKP proposal",
                actions: [
                    {
                        target: this.mock.address,
                        value: 0,
                        signature: "setInterestRate(uint256)",
                        data: ethers.utils.defaultAbiCoder.encode(
                            ["uint256"],
                            [101]
                        ),
                    },
                ],
                descriptionHash:
                    "0xc4f8e201eedb88d8885d83fb8ad14e51d100286d129a6bc6badb55962195f095",
            };

            let proposalHash = await this.firstDAO.hashProposal(
                firstProposal.actions,
                firstProposal.descriptionHash
            );

            await this.firstDAO.propose(
                firstProposal.actions,
                firstProposal.descriptionHash
            );

            expect(await this.firstDAO.proposalIDs(0)).to.be.equal(
                proposalHash
            );

            let proposal = await this.firstDAO.proposals(proposalHash);
            await mineBlocks(this.daoConfig[0]);
            const eligibleVoters = [0, 1];

            let [publicKeyX, publicKeyY] = await this.dkgContract.getPublicKey(
                keyID
            );

            for (let i = 0; i < eligibleVoters.length; i++) {
                let index = this.tree.indexOf(
                    this.commitments[eligibleVoters[i]]
                );
                // console.log(index);
                let path = this.tree.path(index);

                let vote = Voter.getVote(
                    Utils.getBigIntArray([publicKeyX, publicKeyY]),
                    BigInt(this.firstDAO.address),
                    BigInt(proposalHash),
                    VoterData.data1.votingVector[eligibleVoters[i]],
                    VoterData.data1.votingPower[eligibleVoters[i]],
                    this.votingNullifiers[eligibleVoters[i]],
                    path.pathElements,
                    path.pathIndices,
                    this.tree.root
                );
                // console.log(vote);
                let { proof, publicSignals } = await snarkjs.groth16.fullProve(
                    vote.circuitInput,
                    __dirname + "/../zk-resources/wasm/vote_dim3.wasm",
                    __dirname + "/../zk-resources/zkey/vote_dim3_final.zkey"
                );
                proof = Utils.genSolidityProof(
                    proof.pi_a,
                    proof.pi_b,
                    proof.pi_c
                );
                let voteData = [
                    this.tree.root,
                    vote.nullifierHash,
                    vote.Ri,
                    vote.Mi,
                    proof,
                ];
                // console.log(publicSignals);
                await this.firstDAO.castVote(proposalHash, voteData);

                // expect(
                //     await this.firstDAO.nullifierHashes(
                //         proposalHash,
                //         vote.nullifierHash
                //     )
                // ).to.be.eq(true);
            }

            await mineBlocks(this.daoConfig[1]);
            expect(await this.firstDAO.state(proposalHash)).to.be.equal(2);
            await this.firstDAO.tally(proposalHash);

            let requestID = await this.firstDAO.getRequestID(
                keyID,
                this.firstDAO.address,
                proposalHash
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
                    recipientIndex,
                    CommitteeData.data1[i].C,
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
            for (let i = 0; i < eligibleVoters.length; i++) {
                let votingVector =
                    VoterData.data1.votingVector[eligibleVoters[i]];
                for (let j = 0; j < votingVector.length; j++) {
                    result[j] +=
                        VoterData.data1.votingPower[eligibleVoters[i]] *
                        BigInt(votingVector[j]);
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
            // // console.log(proof);
            await this.dkgContract.submitTallyResult(requestID, result, proof);

            await this.firstDAO.finalize(proposalHash);

            await mineBlocks(this.daoConfig[2]);
            expect(await this.firstDAO.state(proposalHash)).to.be.equal(5);

            await this.firstDAO.queue(proposalHash);

            expect(await this.firstDAO.state(proposalHash)).to.be.equal(6);

            await mineBlocks(this.daoConfig[3]);

            await this.firstDAO.execute(proposalHash);
            // expect(
            //     await this.firstDAO.state(proposalHash)
            // ).to.be.equal(8);
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
