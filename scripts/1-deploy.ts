import { expect } from "chai";
import { ethers, network } from "hardhat";
// @ts-ignore
import * as genPoseidonContract from "circomlibjs/src/poseidon_gencontract";
import { ADDRESSES } from "./constants/address";

var t = 3;
var n = 5;

async function main() {
    let accounts = await ethers.getSigners();
    let founder = accounts[0];
    let committees = [];
    for (let i = 0; i < n; i++) {
        committees.push(accounts[i + 1]);
    }
    let chainID = network.config.chainId;
    console.log("Chain ID", chainID);
    console.log("Deployer: ", founder.address);
    let committeeAddresses: string[] = [];
    committees.map((committee, i) => {
        committeeAddresses.push(committee.address);
        console.log(`Committee Member ${i + 1}:`, committee.address);
    });

    let Round2ContributionVerifier = await ethers.getContractFactory(
        "Round2ContributionVerifier",
        founder
    );
    let round2ContributionVerifier = await Round2ContributionVerifier.deploy();

    let FundingVerifierDim3 = await ethers.getContractFactory(
        "FundingVerifierDim3",
        founder
    );
    let fundingVerifierDim3 = await FundingVerifierDim3.deploy();

    let VotingVerifierDim3 = await ethers.getContractFactory(
        "VotingVerifierDim3",
        founder
    );
    let votingVerifierDim3 = await VotingVerifierDim3.deploy();

    let TallyContributionVerifierDim3 = await ethers.getContractFactory(
        "TallyContributionVerifierDim3",
        founder
    );
    let tallyContributionVerifierDim3 =
        await TallyContributionVerifierDim3.deploy();

    let ResultVerifierDim3 = await ethers.getContractFactory(
        "ResultVerifierDim3",
        founder
    );
    let resultVerifierDim3 = await ResultVerifierDim3.deploy();

    let PoseidonUnit2 = await ethers.getContractFactory(
        genPoseidonContract.abi,
        genPoseidonContract.createCode(2),
        founder
    );
    let poseidonUnit2 = await PoseidonUnit2.deploy();
    await poseidonUnit2.deployed();

    let Poseidon = await ethers.getContractFactory("Poseidon", founder);
    let poseidon = await Poseidon.deploy(poseidonUnit2.address);
    await poseidon.deployed();

    let reserveFactor = 0;
    let merkleTreeConfig = [20, poseidon.address];
    console.log("merkleTreeConfig: ", merkleTreeConfig);
    let fundingRoundConfig = [50, 50, 50];
    console.log("fundingRoundConfig", fundingRoundConfig);
    let dkgConfig = [
        round2ContributionVerifier.address,
        fundingVerifierDim3.address,
        votingVerifierDim3.address,
        tallyContributionVerifierDim3.address,
        resultVerifierDim3.address,
    ];
    console.log("dkgConfig", dkgConfig);

    let FundManager = await ethers.getContractFactory("FundManager", founder);
    let fundManager = await FundManager.deploy(
        committeeAddresses,
        reserveFactor,
        merkleTreeConfig,
        fundingRoundConfig,
        dkgConfig
    );

    let dkgContract = await ethers.getContractAt(
        "DKG",
        await fundManager.dkgContract()
    );

    let deploymentObject = {
        Round2ContributionVerifier: round2ContributionVerifier.address,
        FundingVerifierDim3: fundingVerifierDim3.address,
        VotingVerifierDim3: votingVerifierDim3.address,
        TallyContributionVerifierDim3: tallyContributionVerifierDim3.address,
        ResultVerifierDim3: resultVerifierDim3.address,
        PoseidonUnit2: poseidonUnit2.address,
        Poseidon: poseidon.address,
        FundManager: fundManager.address,
        DKG: dkgContract.address,
    };
    console.log(deploymentObject);
}

main().then(() => {
    console.log("DONE");
});
