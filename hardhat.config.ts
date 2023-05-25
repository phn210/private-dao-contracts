import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import "dotenv/config";

// var accounts;
// const mnemonic: string | undefined = process.env.MNEMONIC;

// const keys: any | undefined = process.env.KEYS?.split(" ")
// .map((key) => ({
//         privateKey: key,
//         balance: "1000000000000000000",
// }));

// if (process.env.MNEMONIC) accounts = { mnemonic };
// else if (process.env.KEYS) accounts = keys;

const chainIds = {
    hardhat: 31337,
    eth: 1,
    goerli: 5,
    sepolia: 11155111,
    "mantle-testnet": 5001,
    "bnb-testnet": 97,
};

const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            allowUnlimitedContractSize: false,
            chainId: chainIds.hardhat,
        },
        goerli: {
            accounts: process.env.KEYS?.split(" "),
            chainId: chainIds.goerli,
            url: "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161"
        }
    },
    solidity: {
        compilers: [
            {
                version: "0.8.4",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    contractSizer: {
        alphaSort: true,
        disambiguatePaths: false,
        runOnCompile: true,
        strict: true,
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    },
    mocha: {
        timeout: 1000000,
    },
    gasReporter: {
        currency: "ETH",
        gasPrice: 21,
        enabled: true,
    },
};

export default config;
