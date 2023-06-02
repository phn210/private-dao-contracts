import { expect } from "chai";
import { ethers, network } from "hardhat";
// @ts-ignore
import * as snarkjs from "snarkjs";
import { loadAllContracts } from "./constants/address";
import { CommitteeData, VoterData } from "../test/data";
import { Committee, Voter } from "../libs/index";
import { Utils } from "../libs/utils";

var t = 3;
var n = 5;
// voterIndex from 0;
var voterIndex = 0;
var fundingRoundID = 0;
var keyID = 0;

async function main() {
    let chainID = String(network.config.chainId);
    let accounts = await ethers.getSigners();
    let voter = accounts[1 + n + 3 + voterIndex];
    let contracts = await loadAllContracts(voter, chainID);

    let votingPower = VoterData.data1.votingPower[voterIndex];
    let fundingVector = VoterData.data1.fundingVector[voterIndex];

    console.log(
        "FundingRoundState: ",
        await contracts.fundManager.getFundingRoundState(fundingRoundID)
    );
    console.log("Can only vote if fundingRound is in ACTIVE state");

    let [publicKeyX, publicKeyY] = await contracts.dkgContract.getPublicKey(
        keyID
    );
    publicKeyX = BigInt(publicKeyX);
    publicKeyY = BigInt(publicKeyY);
    let tmp = await contracts.fundManager.getListDAO(fundingRoundID);
    let listDAO = [];
    for (let i = 0; i < tmp.length; i++) {
        listDAO.push(BigInt(tmp[i]));
    }
    let fund = Voter.getFund(
        [publicKeyX, publicKeyY],
        listDAO,
        votingPower,
        fundingVector
    );
    let { proof, publicSignals } = await snarkjs.groth16.fullProve(
        fund.circuitInput,
        __dirname + "/../zk-resources/wasm/fund_dim3.wasm",
        __dirname + "/../zk-resources/zkey/fund_dim3_final.zkey"
    );
    proof = Utils.genSolidityProof(proof.pi_a, proof.pi_b, proof.pi_c);
    await contracts.fundManager.fund(
        fundingRoundID,
        fund.commitment,
        fund.Ri,
        fund.Mi,
        proof,
        {
            value: votingPower,
        }
    );
    console.log("Voter: ", voter.address);
    console.log("Voting power: ", votingPower);
    console.log("Funding vector: ", fundingVector);
}

main().then(() => {
    console.log("DONE");
});
