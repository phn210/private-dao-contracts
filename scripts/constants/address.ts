import { expect } from "chai";
import { ethers, network } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export const ADDRESSES: { [key: string]: { [key: string]: string } } = {
    "31337": {
        Round2ContributionVerifier:"0x5FbDB2315678afecb367f032d93F642f64180aa3",
        FundingVerifierDim3: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
        VotingVerifierDim3: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
        TallyContributionVerifierDim3: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
        ResultVerifierDim3: "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
        PoseidonUnit2: "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707",
        Poseidon: "0x0165878A594ca255338adfa4d48449f69242Eb8F",
        FundManager: "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6",
        DAOManager: "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853",
        DKG: "0x06B1D212B8da92b83AF328De5eef4E211Da02097"
    },
    "5": {
        Round2ContributionVerifier:"0x4D5a5d6704992A29FD0483B5267FD1c73132612b",
        FundingVerifierDim3: "0x916B8204dd038d3F6706272CE9e8f6D87c23Cbb6",
        VotingVerifierDim3: "0x1e5191dC71729AB5907B7971EAF062E2d9acdA92",
        TallyContributionVerifierDim3: "0x315FB9191fce81dd81E6602EC9496FCF124E5dBD",
        ResultVerifierDim3: "0xDF9D337B386cD511Ab9729a69b9E3AB23ab4Db54",
        PoseidonUnit2: "0x23364476F949d80210735331A956461211dB5629",
        Poseidon: "0x0911E33D589057fb088CEe21E20866F940f057f7",
        // FundManager: "0x68Deab74A4f047C893E3b1A538386fE486604984",
        // DAOManager: "0x189a23A0C0B8b4b4211F8e99cd7B54C20ffA4048",
        // DKG: "0x10C2642F2eB0be316E5364C2deFCC22dDa96Ba3C"
        // FundManager: "0x75861AB1b6bE866E6Dda0ced5F1B0a8DE0B969F6",
        // DAOManager: "0x972Da9deCE723E9E0e716Aad7121c6A59C0FaBba",
        // DKG: "0x93Ddcf2C8538827B15045c9e0261f4c040bCb34e",
        FundManager: "0x4F552c423b7Fa28A889E07096B1131FBAd350d51",
        DAOManager: "0xd95B22DAeb060E2Ab68b319aacb94DE1899C210E",
        DKG: "0xe22f737AB1bc03Ce6CB701C3a2Ec1D324cc4DA58",
        QUEUE: "0xCC8c42d6E4da920Ab053d1beE91064b4c80e1797"
    },
    "11155111": {
        Round2ContributionVerifier:"0x0204133D60c28d539802b8fa8b0D4b30f6D0Ca4A",
        FundingVerifierDim3: "0x109D82Fa17F773155668a5F34e9b40416ef5Cb45",
        VotingVerifierDim3: "0x8E73fA58138bA142b821A3f4A54c2a70d71445BB",
        TallyContributionVerifierDim3: "0x365b1ec961fd5DC748Bbb36fa5FF74294Ac23712",
        ResultVerifierDim3: "0xFe712985329d5683471F0eAb21D3C0E109bBA6D5",
        PoseidonUnit2: "0x802eC44fA784F2bac33725729AF22b07EEAddeF0",
        Poseidon: "0x8864267084CA3B080e9087EB5C8c7F8d552099a5",
        FundManager: "0x119cA4DBdC5E30749b85A6eDcB3A0C99444e6062",
        DAOManager: "0x942Ce1A60117a2eF9Aed65C2F4b2b6aba0998F87",
        DKG: "0x17d18135Acd0cA60d0D0d3687C852e84c2230b3a",
        QUEUE: "0x835247c8C195350e48cdb4b5A026D397BEC04d80",
    }
};

export async function loadAllContracts(
    signer: SignerWithAddress,
    chainID: string
) {
    let addresses = ADDRESSES[chainID];

    return {
        round2ContributionVerifier: await ethers.getContractAt(
            "Round2ContributionVerifier",
            addresses["Round2ContributionVerifier"],
            signer
        ),
        fundingVerifierDim3: await ethers.getContractAt(
            "FundingVerifierDim3",
            addresses["FundingVerifierDim3"],
            signer
        ),
        votingVerifierDim3: await ethers.getContractAt(
            "VotingVerifierDim3",
            addresses["VotingVerifierDim3"],
            signer
        ),
        tallyContributionVerifierDim3: await ethers.getContractAt(
            "TallyContributionVerifierDim3",
            addresses["TallyContributionVerifierDim3"],
            signer
        ),
        resultVerifierDim3: await ethers.getContractAt(
            "ResultVerifierDim3",
            addresses["ResultVerifierDim3"],
            signer
        ),
        poseidonUnit2: await ethers.getContractAt(
            "PoseidonUnit2",
            addresses["PoseidonUnit2"],
            signer
        ),
        poseidon: await ethers.getContractAt(
            "Poseidon",
            addresses["Poseidon"],
            signer
        ),
        dkgContract: await ethers.getContractAt(
            "DKG",
            addresses["DKG"],
            signer
        ),
        fundManager: await ethers.getContractAt(
            "FundManager",
            addresses["FundManager"],
            signer
        ),
        daoManager: await ethers.getContractAt(
            "DAOManager",
            addresses["DAOManager"],
            signer
        ),
    };
}
