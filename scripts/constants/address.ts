import { expect } from "chai";
import { ethers, network } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export const ADDRESSES: { [key: string]: { [key: string]: string } } = {
    "31337": {
        Round2ContributionVerifier:"0x4a18b5a9f2d75fd62d871CdC44FF26c0F8Da02eF",
        FundingVerifierDim3: "0x940d1f9c4724F6412E608b30510a4Bbf57CC6b3F",
        VotingVerifierDim3: "0x0204133D60c28d539802b8fa8b0D4b30f6D0Ca4A",
        TallyContributionVerifierDim3: "0x109D82Fa17F773155668a5F34e9b40416ef5Cb45",
        ResultVerifierDim3: "0x8E73fA58138bA142b821A3f4A54c2a70d71445BB",
        PoseidonUnit2: "0x365b1ec961fd5DC748Bbb36fa5FF74294Ac23712",
        Poseidon: "0xFe712985329d5683471F0eAb21D3C0E109bBA6D5",
        FundManager: "0x8864267084CA3B080e9087EB5C8c7F8d552099a5",
        DAOManager: "0x802eC44fA784F2bac33725729AF22b07EEAddeF0",
        DKG: "0xFc4e5fa9baA08675b1C621b3A2Fe866a8dcd1B02",
        Queue: "0xb0E68c1a69AbAC218050745e900ddd6EE467a547",
    },
    "5": {
        Round2ContributionVerifier:"",
        FundingVerifierDim3: "",
        VotingVerifierDim3: "",
        TallyContributionVerifierDim3: "",
        ResultVerifierDim3: "",
        PoseidonUnit2: "",
        Poseidon: "",
        FundManager: "",
        DAOManager: "",
        DKG: "",
        Queue: ""
    },
    "11155111": {
        Round2ContributionVerifier:"",
        FundingVerifierDim3: "",
        VotingVerifierDim3: "",
        TallyContributionVerifierDim3: "",
        ResultVerifierDim3: "",
        PoseidonUnit2: "",
        Poseidon: "",
        FundManager: "",
        DAOManager: "",
        DKG: "",
        Queue: ""
    }
};

// Deployer: 0x1df64aeC03Dc1F00D76f22822FB3B16Fb2C4aB77
// Committee Member 1: 0x1B63c70716e0211fC5F95AB9c3F2AFdebcd1869E
// Committee Member 2: 0x82b5d1638B84637C30e9Dc7b19CCB196fc3cA622
// Committee Member 3: 0x159E2b768C4b22A18462Dfad8c67c609A8009a2F
// Committee Member 4: 0xf5117eE57C0008ddBB22202DCe6702D2D00FBb43
// Committee Member 5: 0x1df64aeC03Dc1F00D76f22822FB3B16Fb2C4aB77

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
