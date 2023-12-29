const { assert, expect } = require("chai")
const { ethers, network, deployments } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("PollContract unit tests", () => {
          let pollContract: any
          let deployer

          beforeEach(async () => {
              const [deployerResult] = await ethers.getSigners()
              deployer = deployerResult

              // deploy all

              await deployments.fixture("all")

              // get addresses of deployments

              const pollAddress = (await deployments.get("PollContract")).address

              // get the ethers connection to the contract by each address

              pollContract = (await ethers.getContractAt("PollContract", pollAddress)).connect(deployer)
          })

          describe("Create new poll", () => {
              it("creates polls and increase newPollId correctly", async () => {
                  let pollsCount
                  const now = new Date()
                  const threeDaysFromNow = new Date(now.setDate(now.getDate() + 3)).getTime()
                  const newPoll1 = [
                      "Quien ganara gran hermano?",
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                      false,
                      now.getTime(),
                      threeDaysFromNow,
                      ["Alan", "Martin", "Joan"]
                  ]

                  const newPoll2 = [
                      "Va a llover mañana en la ciudad?",
                      "LLLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                      false,
                      now.getTime(),
                      threeDaysFromNow,
                      ["Si", "No"]
                  ]

                  await pollContract.createPoll(...newPoll1)

                  await pollContract.createPoll(...newPoll2)

                  pollsCount = await pollContract.getPollsCount()

                  const polls = await pollContract.getPolls()

                  assert.equal(pollsCount, 2, polls.length)
              })
          })
      })
