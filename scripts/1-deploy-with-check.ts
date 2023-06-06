import { ethers, network } from "hardhat";
// @ts-ignore
import * as genPoseidonP2Contract from "circomlibjs/src/poseidon_gencontract";
import { ADDRESSES } from "./constants/address";

var t = 3;
var n = 5;
var numOfDAOs = 3;

var config: {
    governorConfig: {
        votingDelay: 3;
        votingPeriod: 30;
    };
    timelockConfig: {
        minTimelockDelay: 1;
        maxTimelockDelay: 100000;
        delay: 10;
        gracePeriod: 100;
    };
};

export async function deploy(logging: boolean) {
    let accounts = await ethers.getSigners();
    let owner = accounts[0];
    let committeeSigners = [];
    for (let i = 0; i < n-1; i++) {
        committeeSigners.push(accounts[i + 1]);
    }
    committeeSigners.push(owner);

    if (logging) console.log("Chain ID:", network.config.chainId);
    if (logging) console.log("Deployer:", owner.address);
    committeeSigners.map((committee, i) => {
        if (logging) console.log(`Committee Member ${i+1}:`, committee.address);
    });

    async function getContract(name: string) {
        const address = ADDRESSES[String(network.config.chainId)][name] || "";
        if (address == "") {
            if (name == "PoseidonUnit2") return await ethers.getContractFactory(
                genPoseidonP2Contract.abi,
                genPoseidonP2Contract.createCode(),
                owner
            );
            return await ethers.getContractFactory(name, owner);
        } else {
            return await ethers.getContractAt(name, address, owner);
        }
    }

    // Deploy ZKP Verifier contracts
    let Round2ContributionVerifier = await getContract("Round2ContributionVerifier");
    let round2ContributionVerifier = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            if (logging) console.log(`${name} (EXISTED):`, contract.address);
            return contract;
        }
        else {
            let ct = await contract.deploy(...init);
            if (logging) console.log(`${name} (NEW):`, ct.address);
            return ct;
        }
    })(Round2ContributionVerifier, "Round2ContributionVerifier");

    let FundingVerifier = await getContract("FundingVerifier");
    let fundingVerifier = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            if (logging) console.log(`${name} (EXISTED):`, contract.address);
            return contract;
        }
        else {
            let ct = await contract.deploy(...init);
            if (logging) console.log(`${name} (NEW):`, ct.address);
            return ct;
        }
    })(FundingVerifier, "FundingVerifier");

    let FundAllocationVerifier = await getContract("FundAllocationVerifier");
    let fundAllocationVerifier = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            if (logging) console.log(`${name} (EXISTED):`, contract.address);
            return contract;
        }
        else {
            let ct = await contract.deploy(...init);
            if (logging) console.log(`${name} (NEW):`, ct.address);
            return ct;
        }
    })(FundAllocationVerifier, "FundAllocationVerifier");

    let VotingVerifier = await getContract("VotingVerifier");
    let votingVerifier = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            if (logging) console.log(`${name} (EXISTED):`, contract.address);
            return contract;
        }
        else {
            let ct = await contract.deploy(...init);
            if (logging) console.log(`${name} (NEW):`, ct.address);
            return ct;
        }
    })(VotingVerifier, "VotingVerifier");

    let VoteTallyVerifier = await getContract("VoteTallyVerifier");
    let voteTallyVerifier = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            if (logging) console.log(`${name} (EXISTED):`, contract.address);
            return contract;
        }
        else {
            let ct = await contract.deploy(...init);
            if (logging) console.log(`${name} (NEW):`, ct.address);
            return ct;
        }
    })(VoteTallyVerifier, "VoteTallyVerifier");

    // Deploy Poseidon2 contract
    let PoseidonUnit2 = await getContract("PoseidonUnit2");
    let poseidonUnit2 = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            if (logging) console.log(`${name} (EXISTED):`, contract.address);
            return contract;
        }
        else {
            let ct = await contract.deploy(...init);
            if (logging) console.log(`${name} (NEW):`, ct.address);
            return ct;
        }
    })(PoseidonUnit2, "PoseidonUnit2");

    let Poseidon = await getContract("Poseidon");
    let poseidon = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            if (logging) console.log(`${name} (EXISTED):`, contract.address);
            return contract;
        }
        else {
            let ct = await contract.deploy(...init);
            if (logging) console.log(`${name} (NEW):`, ct.address);
            return ct;
        }
    })(Poseidon, "Poseidon", [poseidonUnit2.address]);

    // Deploy DKG contract
    let DKG = await getContract("DistributedKeyGeneration");
    let dkg = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            if (logging) console.log(`${name} (EXISTED):`, contract.address);
            return contract;
        }
        else {
            let ct = await contract.deploy(...init);
            if (logging) console.log(`${name} (NEW):`, ct.address);
            return ct;
        }
    })(DKG, "DKG", [
        t,
        n,
        round2ContributionVerifier.address,
        fundAllocationVerifier.address,
        voteTallyVerifier.address
    ]);

    for (let i = 0; i < n; i++) {
        if (await dkg.isCommittee(committeeSigners[i].address))
            if (logging) console.log(`Committee ${i+1} added`, committeeSigners[i].address);
        else {
            await dkg.addCommittee(committeeSigners[i].address);
            if (logging) console.log(`Add committee ${i+1} successfully`, committeeSigners[i].address);
        }
    }

    // Deploy Funding contract
    let Funding = await getContract("Funding");
    let funding = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            if (logging) console.log(`${name} (EXISTED):`, contract.address);
            return contract;
        }
        else {
            let ct = await contract.deploy(...init);
            if (logging) console.log(`${name} (NEW):`, ct.address);
            return ct;
        }
    })(Funding, "Funding", [
        fundingVerifier.address,
        votingVerifier.address,
        dkg.address,
        poseidon.address,
        12
    ]);

    let DAOFactoryAddress = await funding.daoFactory();
    let daoFactory = await ethers.getContractAt(
        "DAOFactory",
        DAOFactoryAddress,
        owner
    );
    if (logging) console.log("DAOFactory (EXISTED):", daoFactory.address);

    if (logging) console.log("Creating 3 DAOs...");
    let daoExisted = await daoFactory.getTotalDAOs();
    // if (logging) console.log(daoExisted);
    if (daoExisted < 3) {
        await Promise.all(
            [...Array(3-daoExisted)].map(async (i) => {
                await funding.createDAO([
                    [3, 20],
                    [1, 100000, 10, 100],
                ]);
            })
        );
    }

    let DAOAddresses = [
        await daoFactory.daos(0),
        await daoFactory.daos(1),
        await daoFactory.daos(2),
    ];
    if (logging) console.log("DAO 0:", DAOAddresses[0]);
    if (logging) console.log("DAO 1:", DAOAddresses[1]);
    if (logging) console.log("DAO 2:", DAOAddresses[2]);

    // Deploy mock contract
    let firstDAO = await ethers.getContractAt(
        "Governor",
        DAOAddresses[0],
        owner
    );
    let timelockAddress = await firstDAO.timelock();
    if (logging) console.log("Deploy mock contract for DAO 0...");
    let Mock = await getContract("Mock");
    let mock = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            if (logging) console.log(`${name} (EXISTED):`, contract.address);
            return contract;
        }
        else {
            let ct = await contract.deploy(...init);
            if (logging) console.log(`${name} (NEW):`, ct.address);
            return ct;
        }
    })(Mock, "Mock", [timelockAddress]);

    return {
        _: {
            Round2ContributionVerifier: round2ContributionVerifier,
            FundingVerifier: fundingVerifier,
            FundAllocationVerifier: fundAllocationVerifier,
            VotingVerifier: votingVerifier,
            VoteTallyVerifier: voteTallyVerifier,
            PoseidonUnit2: poseidonUnit2,
            Poseidon: poseidon,
            DKG: dkg,
            Funding: funding,
            DAOFactory: daoFactory,
            Mock: mock,
            FirstDAO: firstDAO
        },
        $: {
            deployer: owner,
            committee: committeeSigners,
            voters: committeeSigners
        },
        t,
        n,
        config
    }
}

// deploy(true).then(() => {
//     console.log("DEPLOYING DONE!");
//     // process.exit(10);
// });