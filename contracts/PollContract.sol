// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <0.9.0;

error PollContract_NotEnoughOptionsProvided();
error PollContract_NeededBiggerClosesAtDate(uint256 receivedTime, uint256 blockTimestamp);
error PollContract_AlreadyVotedInPoll();

contract PollContract {
    enum PollStatus {
        OPEN,
        CLOSED
    }

    struct Option {
        uint256 optionId;
        uint256 pollId;
        uint256 numberOfVotes;
        string name;
    }

    struct Vote {
        uint256 pollId;
        address voter;
        Option[] optionsVoted;
    }

    struct Poll {
        uint256 id;
        string name;
        string description;
        bool allowMultipleOptionsSelected;
        uint256 createdAt;
        uint256 closesAt;
        address creator;
        uint256 numberOfOptions;
        PollStatus status;
        Vote[] votes;
    }

    uint256 public pollsCount;
    mapping(uint256 => Poll) private polls;
    //address is the voter and uint256 for the pollId
    mapping(address => mapping(uint256 => Vote)) private globalVotesByAddress;
    // poll id and then option id
    mapping(uint256 => mapping(uint256 => Option)) pollOptions;

    constructor() {}

    function createPoll(
        string memory _name,
        string memory _description,
        bool _allowMultipleOptionsSelected,
        uint256 _closesAt,
        string[] memory _options
    ) external payable {
        uint256 aproxCurrentTime = block.timestamp;
        if (_closesAt < aproxCurrentTime) {
            revert PollContract_NeededBiggerClosesAtDate(_closesAt, aproxCurrentTime);
        }
        if (_options.length < 2) {
            revert PollContract_NotEnoughOptionsProvided();
        }

        uint256 newPollId = pollsCount;
        Poll storage newPoll = polls[newPollId];

        newPoll.id = newPollId;
        newPoll.name = _name;
        newPoll.description = _description;
        newPoll.allowMultipleOptionsSelected = _allowMultipleOptionsSelected;
        newPoll.createdAt = aproxCurrentTime;
        newPoll.closesAt = _closesAt;
        newPoll.creator = msg.sender;
        newPoll.status = PollStatus.OPEN;

        newPoll.numberOfOptions = 0;

        for (uint256 i = 0; i < _options.length; i++) {
            pollOptions[newPollId][i] = Option(i, newPollId, 0, _options[i]);
            newPoll.numberOfOptions++;
        }

        pollsCount++;
    }

    function votePoll(uint256 _pollId, uint256[] memory optionsVotedIds) external payable {
        // checking that sender did not already vote in poll
        address testAddress = globalVotesByAddress[msg.sender][_pollId].voter;
        if (testAddress != address(0)) {
            revert PollContract_AlreadyVotedInPoll();
        }

        Vote storage newVote = globalVotesByAddress[msg.sender][_pollId];

        for (uint256 i = 0; i < optionsVotedIds.length; i++) {
            Option storage optionVoted = pollOptions[_pollId][optionsVotedIds[i]];
            newVote.optionsVoted.push(optionVoted);
            optionVoted.numberOfVotes++;
        }

        newVote.pollId = _pollId;
        newVote.voter = msg.sender;

        polls[_pollId].votes.push(newVote);
    }

    function getPolls() public view returns (Poll[] memory) {
        Poll[] memory mPolls = new Poll[](pollsCount);
        for (uint256 i = 0; i < pollsCount; i++) {
            Poll storage sPoll = polls[i];
            mPolls[i] = sPoll;
        }
        return mPolls;
    }

    function getPollById(uint256 _pollId) public view returns (Poll memory) {
        return polls[_pollId];
    }

    function getPollsCount() public view returns (uint256) {
        return pollsCount;
    }

    function getPollOptions(uint256 _pollId) public view returns (Option[] memory) {
        Poll memory pollToRevise = getPollById(_pollId);

        Option[] memory mOptions = new Option[](pollToRevise.numberOfOptions);

        for (uint256 i = 0; i < pollToRevise.numberOfOptions; i++) {
            Option storage sOption = pollOptions[_pollId][i];
            mOptions[i] = sOption;
        }

        return mOptions;
    }

    function getMyVoteInPoll(uint256 _pollId) public view returns (Vote memory) {
        return globalVotesByAddress[msg.sender][_pollId];
    }
}
