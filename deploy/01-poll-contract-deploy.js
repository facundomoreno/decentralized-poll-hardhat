const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { ethers, network, deployments } = require("hardhat")
const { verify } = require("../utils/verify")

const VRF_SUB_FUND_AMOUNT = ethers.parseEther("2")

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    // const chainId = network.config.chainId
    // let vrfCoordinatorV2Address, subscriptionId

    // if (developmentChains.includes(network.name)) {
    //     vrfCoordinatorV2Address = (await deployments.get("VRFCoordinatorV2Mock")).address
    //     const vrfCoordinatorV2Mock = await ethers.getContractAt("VRFCoordinatorV2Mock", vrfCoordinatorV2Address)
    //     const transactionResponse = await vrfCoordinatorV2Mock.createSubscription()
    //     await transactionResponse.wait()
    //     subscriptionId = 1
    //     await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, VRF_SUB_FUND_AMOUNT)
    // } else {
    //     vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"]
    //     subscriptionId = networkConfig[chainId]["subscriptionId"]
    // }
    const args = []

    const pollContract = await deploy("PollContract", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1
    })

    // if (developmentChains.includes(network.name)) {
    //     coordinatorAddress = (await deployments.get("VRFCoordinatorV2Mock")).address

    //     vrfCoordinatorV2Mock = await ethers.getContractAt("VRFCoordinatorV2Mock", coordinatorAddress)

    //     await vrfCoordinatorV2Mock.addConsumer(subscriptionId, raffle.address)
    // }

    if (!developmentChains.includes(network.name)) {
        log("Verifying...")
        await verify(pollContract.address, args)
    }

    log("-----------------------------------")
}

module.exports.tags = ["all", "poll_contract"]
