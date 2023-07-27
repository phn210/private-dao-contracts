import { ethers, network } from "hardhat";
import { Poseidon as PoseidonLib, Utils } from "distributed-key-generation";
import { ADDRESSES } from "./constants/address";

export async function deploy(alwayDeploy: boolean, logging: boolean) {
    let t = 3;
    let n = 5;
    let numOfDAOs = 3;

    let config = {
        merkleTreeDepth: 20,
        fundingRoundConfig: [10, 100, 40],
        daoConfig: [10, 100, 40, 10, 10],
        requiredDeposit: 0,
    };
    let accounts = await ethers.getSigners();
    let owner = accounts[0];
    let committeeSigners = [];
    for (let i = 0; i < n; i++) {
        committeeSigners.push(accounts[i]);
    }

    async function getContract(name: string) {
        const address = ADDRESSES[String(network.config.chainId)][name] || "";
        if (address == "" || alwayDeploy) {
            if (name == "PoseidonUnit2") {
                let poseidonContract = PoseidonLib.getPoseidonContract();
                return await ethers.getContractFactory(
                    poseidonContract.abi,
                    poseidonContract.code,
                    owner
                );
            }
            if (name == "DAO" || name == "Mock")
                return await ethers.getContractAt(
                    name,
                    "0x0000000000000000000000000000000000000000",
                    owner
                );
            return await ethers.getContractFactory(name, owner);
        } else {
            return await ethers.getContractAt(name, address, owner);
        }
    }

    let result: any = {};
    // Deploy ZKP Verifier contracts
    let Round2ContributionVerifier = await getContract(
        "Round2ContributionVerifier"
    );
    let round2ContributionVerifier = await (async (
        contract,
        name,
        init: any = []
    ) => {
        if (contract instanceof ethers.Contract) {
            result[name + " (EXISTED)"] = contract.address;
            return contract;
        } else {
            let ct = await contract.deploy(...init);
            result[name + " (NEW)"] = ct.address;
            result[name + " (NEW)"] = ct.address;
            return ct;
        }
    })(Round2ContributionVerifier, "Round2ContributionVerifier");

    let FundingVerifier = await getContract("FundingVerifierDim3");
    let fundingVerifier = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            result[name + " (EXISTED)"] = contract.address;
            return contract;
        } else {
            let ct = await contract.deploy(...init);
            result[name + " (NEW)"] = ct.address;
            return ct;
        }
    })(FundingVerifier, "FundingVerifierDim3");

    let VotingVerifier = await getContract("VotingVerifierDim3");
    let votingVerifier = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            result[name + " (EXISTED)"] = contract.address;
            return contract;
        } else {
            let ct = await contract.deploy(...init);
            result[name + " (NEW)"] = ct.address;
            return ct;
        }
    })(VotingVerifier, "VotingVerifierDim3");

    let TallyContributionVerifier = await getContract(
        "TallyContributionVerifierDim3"
    );
    let tallyContributionVerifier = await (async (
        contract,
        name,
        init: any = []
    ) => {
        if (contract instanceof ethers.Contract) {
            result[name + " (EXISTED)"] = contract.address;
            return contract;
        } else {
            let ct = await contract.deploy(...init);
            result[name + " (NEW)"] = ct.address;
            return ct;
        }
    })(TallyContributionVerifier, "TallyContributionVerifierDim3");

    let ResultVerifier = await getContract("ResultVerifierDim3");
    let resultVerifier = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            result[name + " (EXISTED)"] = contract.address;
            return contract;
        } else {
            let ct = await contract.deploy(...init);
            result[name + " (NEW)"] = ct.address;
            return ct;
        }
    })(ResultVerifier, "ResultVerifierDim3");

    let dkgConfig = [
        round2ContributionVerifier.address,
        fundingVerifier.address,
        votingVerifier.address,
        tallyContributionVerifier.address,
        resultVerifier.address,
    ];

    // Deploy Poseidon2 contract
    let PoseidonUnit2 = await getContract("PoseidonUnit2");
    let poseidonUnit2 = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            result[name + " (EXISTED)"] = contract.address;
            return contract;
        } else {
            let ct = await contract.deploy(...init);
            result[name + " (NEW)"] = ct.address;
            return ct;
        }
    })(PoseidonUnit2, "PoseidonUnit2");

    let Poseidon = await getContract("Poseidon");
    let poseidon = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            result[name + " (EXISTED)"] = contract.address;
            return contract;
        } else {
            let ct = await contract.deploy(...init);
            result[name + " (NEW)"] = ct.address;
            return ct;
        }
    })(Poseidon, "Poseidon", [poseidonUnit2.address]);

    // Deploy DAOManager contract
    let DAOManager = await getContract("DAOManager");
    let daoManager = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            result[name + " (EXISTED)"] = contract.address;
            return contract;
        } else {
            let ct = await contract.deploy(...init);
            result[name + " (NEW)"] = ct.address;
            return ct;
        }
    })(DAOManager, "DAOManager", [config.requiredDeposit]);

    // Deploy DAOManager contract
    let FundManager = await getContract("FundManager");
    let fundManager = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            result[name + " (EXISTED)"] = contract.address;
            return contract;
        } else {
            let ct = await contract.deploy(...init);
            result[name + " (NEW)"] = ct.address;
            return ct;
        }
    })(FundManager, "FundManager", [
        committeeSigners.map((com) => com.address),
        daoManager.address,
        0,
        [config.merkleTreeDepth, poseidon.address],
        config.fundingRoundConfig,
        dkgConfig,
    ]);

    let dkgAddress = await fundManager.dkgContract();

    // Deploy DKG contract
    let dkg = await ethers.getContractAt("DKG", dkgAddress);
    result["DKG"] = dkg.address;

    let queueAddress = await fundManager.fundingRoundQueue();

    // Deploy DKG contract
    let queue = await ethers.getContractAt("Queue", queueAddress);
    result["Queue"] = queue.address;

    if (
        (await daoManager.fundManager()).toLowerCase() !=
        fundManager.address.toLowerCase()
    ) {
        await daoManager.setFundManager(fundManager.address);
        console.log("Setting FundManager for DAOManager contract . . .");
    }

    if ((await daoManager.dkg()).toLowerCase() != dkg.address.toLowerCase()) {
        await daoManager.setDKG(dkg.address);
        console.log("Setting DKG for DAOManager contract . . .");
    }

    let DAO = await getContract("DAO");
    let dao = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            result[name + " (EXISTED)"] = contract.address;
            return contract;
        } else {
            let ct = await contract.deploy(...init);
            result[name + " (NEW)"] = ct.address;
            return ct;
        }
    })(DAO, "DAO");

    let Mock = await getContract("Mock");
    let mock = await (async (contract, name, init: any = []) => {
        if (contract instanceof ethers.Contract) {
            result[name + " (EXISTED)"] = contract.address;
            return contract;
        } else {
            let ct = await contract.deploy(...init);
            result[name + " (NEW)"] = ct.address;
            return ct;
        }
    })(Mock, "Mock");

    if (logging) {
        Utils.logFullObject(result);
    }
    console.log("DEPLOYING DONE!");
    return {
        _: {
            Round2ContributionVerifier: round2ContributionVerifier,
            FundingVerifier: fundingVerifier,
            VotingVerifier: votingVerifier,
            TallyContributionVerifier: tallyContributionVerifier,
            PoseidonUnit2: poseidonUnit2,
            Poseidon: poseidon,
            FundManager: fundManager,
            DAOManager: daoManager,
            QUEUE: queue,
            DKG: dkg,
            DAO: dao,
            Mock: mock,
        },
        $: {
            deployer: owner,
            committee: committeeSigners,
            voters: committeeSigners,
        },
        t,
        n,
        config,
    };
}

