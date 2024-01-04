import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "hardhat-deploy"
import dotenv from "dotenv"
dotenv.config()

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY!
const COINMARKET_API_KEY = process.env.COINMARKET_API_KEY

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.19",
        settings: {
            optimizer: {
                enabled: true,
                runs: 1000
            }
        }
    },
    etherscan: {
        apiKey: {
            sepolia: "K28VG6375TK92PKXEAW5Y7JBMUFYBSYSJE"
        }
    },
    networks: {
        sepolia: {
            url: SEPOLIA_RPC_URL,
            accounts: [PRIVATE_KEY],
            chainId: 11155111
        },
        hardhat: {
            chainId: 31337
        },
        localhost: {
            url: "http://127.0.0.1:8545/",
            chainId: 31337
        }
    },
    namedAccounts: {
        deployer: {
            default: 0
        },
        player: {
            default: 1
        }
    },
    gasReporter: {
        enabled: true,
        outputFile: "gas-report.txt",
        noColors: true,
        currency: "USD",
        coinmarketcap: COINMARKET_API_KEY
    }
}

export default config
