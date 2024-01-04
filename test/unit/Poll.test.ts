const { assert, expect } = require("chai")
const { ethers, network, deployments } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("PollContract unit tests", () => {
          let pollContract: any
          let deployer: any
          let pollAddress: string

          beforeEach(async () => {
              const [deployerResult] = await ethers.getSigners()
              deployer = deployerResult

              // deploy all

              await deployments.fixture("all")

              // get addresses of deployments

              pollAddress = (await deployments.get("PollContract")).address

              // get the ethers connection to the contract by each address

              pollContract = (await ethers.getContractAt("PollContract", pollAddress)).connect(deployer)
          })

          describe("Create new poll", () => {
              it("creates polls, increase newPollId correctly and add options to global mapping", async () => {
                  let pollsCount
                  const now = new Date()

                  // working with unix timestamp.  Normal date = new Date(unixT * 1000)

                  const threeDaysFromNow = Math.floor(new Date(now.setDate(now.getDate() + 3)).getTime() / 1000)
                  const newPoll1 = [
                      "Quien ganara gran hermano?",
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                      true,
                      threeDaysFromNow,
                      ["Alan", "Martin", "Joan"]
                  ]

                  const newPoll2 = [
                      "Va a llover mañana en la ciudad?",
                      "LLLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                      true,
                      threeDaysFromNow,
                      ["Si", "No"]
                  ]

                  await pollContract.createPoll(...newPoll1)

                  await pollContract.createPoll(...newPoll2)

                  pollsCount = await pollContract.getPollsCount()

                  const polls = await pollContract.getPolls()

                  assert.equal(pollsCount, 2, polls.length)

                  const pollOptionsOfFirst = (await pollContract.getPollById(0))[1]

                  assert.equal(pollOptionsOfFirst.length, 3)

                  const pollOptionsOfSecond = (await pollContract.getPollById(1))[1]

                  assert.equal(pollOptionsOfSecond.length, 2)
              })

              it("fails if you dont send enough options to poll", async () => {
                  let pollsCount
                  const now = new Date()

                  const threeDaysFromNow = Math.floor(new Date(now.setDate(now.getDate() + 3)).getTime() / 1000)
                  const newPoll1 = [
                      "Quien ganara gran hermano?",
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                      true,
                      threeDaysFromNow,
                      ["Alan"]
                  ]

                  await expect(pollContract.createPoll(...newPoll1)).to.be.rejectedWith(
                      "PollContract_NotEnoughOptionsProvided"
                  )

                  pollsCount = await pollContract.getPollsCount()

                  assert.equal(pollsCount, 0)
              })
              it("fails if you dont send a closesAt after the aprox current time", async () => {
                  await network.provider.send("evm_increaseTime", [100000000])
                  await network.provider.send("evm_mine", [])

                  const breakingClosesAt = 1703866244 // Tue Jan 20 1970 14:17:46 GMT-0300
                  const newPoll1 = [
                      "Quien ganara gran hermano?",
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                      true,

                      breakingClosesAt,
                      ["Alan", "Juan"]
                  ]

                  await expect(pollContract.createPoll(...newPoll1)).to.be.rejectedWith(
                      "PollContract_NeededBiggerClosesAtDate"
                  )
              })
          })
          describe("Vote with multiple options disabled", async () => {
              beforeEach(async () => {
                  const now = new Date()

                  const threeDaysFromNow = Math.floor(new Date(now.setDate(now.getDate() + 3)).getTime() / 1000)
                  const newPoll1 = [
                      "Quien ganara gran hermano?",
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                      false,
                      threeDaysFromNow,
                      ["Alan", "Martin", "Joan"]
                  ]
                  await pollContract.createPoll(...newPoll1)
              })
              it("add new vote to poll, updating the option number of votes", async () => {
                  await pollContract.votePoll(0, [0])

                  const myVoteResult = await pollContract.getMyVoteInPoll(0)

                  const pollResult = await pollContract.getPollById(0)

                  const pollVotes = pollResult[2]

                  assert.equal(myVoteResult.voter, deployer.address)
                  assert.equal(pollVotes, 1)

                  const firstPollOptions = (await pollContract.getPollById(0))[1]

                  assert.equal(firstPollOptions[0].numberOfVotes, 1)
                  assert.equal(firstPollOptions[1].numberOfVotes, firstPollOptions[2].numberOfVotes, 0)
              })
              it("fails if you already vote in the poll", async () => {
                  // first valid vote
                  await pollContract.votePoll(0, [2])

                  // second vote that should fail
                  await expect(pollContract.votePoll(0, [1])).to.be.rejectedWith("PollContract_AlreadyVotedInPoll")
              })
              it("fails if you vote with wrong amount of options", async () => {
                  await expect(pollContract.votePoll(0, [])).to.be.rejectedWith(
                      "PollContract_WrongAmountOfOptionsProvided"
                  )
                  await expect(pollContract.votePoll(0, [0, 1])).to.be.rejectedWith(
                      "PollContract_WrongAmountOfOptionsProvided"
                  )
              })
              it("fails if you vote after the poll closed", async () => {
                  await network.provider.send("evm_increaseTime", [60 * 60 * 24 * 3 + 30]) // increase 3 days and 30 seconds
                  await network.provider.send("evm_mine", [])

                  await expect(pollContract.votePoll(0, [0])).to.be.rejectedWith("PollContract_PollIsClosed")
              })
          })

          describe("Vote with multiple options allowed", () => {
              beforeEach(async () => {
                  const now = new Date()

                  const threeDaysFromNow = Math.floor(new Date(now.setDate(now.getDate() + 3)).getTime() / 1000)
                  const newPoll1 = [
                      "Quien ganara gran hermano?",
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                      true,
                      threeDaysFromNow,
                      ["Alan", "Martin", "Joan"]
                  ]
                  await pollContract.createPoll(...newPoll1)
              })
              it("add new votes to poll, updating the option number of votes", async () => {
                  await pollContract.votePoll(0, [0, 1])

                  const signers = await ethers.getSigners()

                  const contractConnectedTo3 = (await ethers.getContractAt("PollContract", pollAddress)).connect(
                      signers[3]
                  )
                  const contractConnectedTo4 = (await ethers.getContractAt("PollContract", pollAddress)).connect(
                      signers[4]
                  )
                  const contractConnectedTo5 = (await ethers.getContractAt("PollContract", pollAddress)).connect(
                      signers[5]
                  )

                  await contractConnectedTo3.votePoll(0, [2])
                  await contractConnectedTo4.votePoll(0, [1])
                  await contractConnectedTo5.votePoll(0, [0, 1])

                  const myVoteResult = await pollContract.getMyVoteInPoll(0)

                  const pollResult = await pollContract.getPollById(0)

                  const pollVotes = pollResult[2]

                  assert.equal(myVoteResult.voter, deployer.address)
                  assert.equal(pollVotes, 4)

                  const firstPollOptions = pollResult[1]

                  assert.equal(firstPollOptions[0].numberOfVotes, 2)
                  assert.equal(firstPollOptions[1].numberOfVotes, 3)
                  assert.equal(firstPollOptions[2].numberOfVotes, 1)
              })
          })
      })
