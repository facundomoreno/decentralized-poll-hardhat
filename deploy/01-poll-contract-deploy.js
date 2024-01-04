const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { ethers, network, deployments } = require("hardhat")
const { verify } = require("../utils/verify")

const VRF_SUB_FUND_AMOUNT = ethers.parseEther("2")

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const args = []

    const pollContract = await deploy("PollContract", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })

    if (!developmentChains.includes(network.name)) {
        log("Verifying...")
        await verify(pollContract.address, args)
    }

    log("-----------------------------------")
}

module.exports.tags = ["all", "poll_contract"]
