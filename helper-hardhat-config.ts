const { ethers } = require("hardhat")

export interface networkConfigItem {
    name: string,
    blockConfirmations?: number // DESPUES LOS USO EN EL DEPLOY. https://github.com/PatrickAlphaC/hardhat-fund-me-fcc/blob/84271e7002e55d86c90b26466ff27bc067f25de0/deploy/01-deploy-fund-me.ts#L29
  }

  export interface networkConfigInfo {
    [key: string]: networkConfigItem
  }
  

const networkConfig : networkConfigInfo = {
    11155111: {
        name: "sepolia",
        blockConfirmations: 4

    },
    31337: {
        name: "hardhat",
        blockConfirmations: 1
    }
}
const developmentChains = ["hardhat", "localhost"]


module.exports = {
    networkConfig,
    developmentChains
}
