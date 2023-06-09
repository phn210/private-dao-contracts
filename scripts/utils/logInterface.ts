import fs from 'fs';
import { ethers, network } from "hardhat";

async function main() {
    const names = [
        "Round2ContributionVerifier",
        "FundingVerifierDim3",
        "VotingVerifierDim3",
        "TallyContributionVerifierDim3",
        "ResultVerifierDim3",
        "PoseidonUnit2",
        "Poseidon",
        "FundManager",
        "DAOManager",
        "DKG",
        "DAO",
        "Queue"
    ]
    
    const output: {[key: string]: any} = await Promise.all(names.map(e => ethers.getContractFactory(e)));
    
    // const deployed = helper.deployed();

    let contracts = Object.keys(output).filter(
        (name: string) => output[name] && output[name].constructor?.name == 'ContractFactory'
    ).reduce(
        (obj, name) => 
            Object.assign(obj, {
                [names[Number(name)].toLowerCase()]: {
                    // address: deployed[network.name][names[name].toLowerCase()] ?? '',
                    address: '',
                    interface: output[name].interface.format('minimal')
                }
            })
        , {
            ['']: {
                chainId: network.config.chainId ?? ''
            } 
        }
    );
    
    fs.writeFileSync(`${process.cwd()}/scripts/constants/${network.config.chainId}.ts`, 'export default ' + JSON.stringify(contracts));
    // console.log(contracts)
}

main()
.then(() => process.exit())
.catch((e) => {
    console.error(e);
    process.exit(1);
})
