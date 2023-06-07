import crypto from 'crypto';
import { ethers } from "hardhat";
import { deploy } from "../1-deploy-with-check";

async function main() {
    const { _, $, t, n, config } = await deploy(false);

    const daoId = 0;
    const firstProposal = {
        shortDes: "Apply for funding round proposal",
        actions: [
            {
                target: _.DAOManager.address,
                value: 0,
                signature: "applyForFunding()",
                data: ethers.utils.defaultAbiCoder.encode(
                    [],
                    []
                ),
            },
        ],
        descriptionHash: '0x'+crypto.randomBytes(32).toString('hex')
    };
    console.log(firstProposal);
    
}

main().then(() => {
    console.log("DONE");
    process.exit();
});
