// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <0.9.0;

error PollContract_NotEnoughOptionsProvided();
error PollContract_CheckStringsLength();
error PollContract_NeededBiggerClosesAtDate(uint256 receivedTime, uint256 blockTimestamp);
error PollContract_AlreadyVotedInPoll();
error PollContract_PollIsClosed();
error PollContract_PollIsOpen();
error PollContract_WrongAmountOfOptionsProvided();

contract PollContract {
    struct Option {
        uint256 optionId;
        uint256 pollId;
        uint256 numberOfVotes;
        string name;
    }

    struct Vote {
        uint256 voteId;
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
    }

    event PollCreated(Poll pollCreated);
    event NewVoteInPoll(Vote newVote);

    uint256 private pollsCount;
    // poll id
    mapping(uint256 => Poll) private polls;
    //address (voter) => pollId
    mapping(address => mapping(uint256 => Vote)) private globalVotesByAddress;
    // poll id => option id
    mapping(uint256 => mapping(uint256 => Option)) private pollOptions;
    // poll id => voteId
    mapping(uint256 => mapping(uint256 => Vote)) private pollVotes;
    // poll id
    mapping(uint256 => uint256) amountOfVotesInPoll;

    constructor() {}

    function createPoll(
        string calldata _name,
        string calldata _description,
        bool _allowMultipleOptionsSelected,
        uint256 _closesAt,
        string[] calldata _options
    ) external payable {
        uint256 aproxCurrentTime = block.timestamp;
        bytes memory nameToBytes = bytes(_name);
        bytes memory descriptionToBytes = bytes(_description);
        if (nameToBytes.length > 60 || descriptionToBytes.length > 500) {
            revert PollContract_CheckStringsLength();
        }
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

        newPoll.numberOfOptions = 0;

        for (uint256 i = 0; i < _options.length; i++) {
            bytes memory optionNameToBytes = bytes(_options[i]);
            if (optionNameToBytes.length > 60) {
                revert PollContract_CheckStringsLength();
            }
            pollOptions[newPollId][i] = Option(i, newPollId, 0, _options[i]);
            newPoll.numberOfOptions++;
        }

        pollsCount++;

        emit PollCreated(newPoll);
    }

    function votePoll(uint256 _pollId, uint256[] calldata optionsVotedIds) external payable {
        // checking that sender did not already vote in poll

        Poll storage poll = polls[_pollId];
        address addressForCheck = globalVotesByAddress[msg.sender][_pollId].voter;

        if (addressForCheck != address(0)) {
            revert PollContract_AlreadyVotedInPoll();
        }

        if (poll.closesAt < block.timestamp) {
            revert PollContract_PollIsClosed();
        }

        if (
            ((poll.allowMultipleOptionsSelected == false) && optionsVotedIds.length > 1) || (optionsVotedIds.length < 1)
        ) {
            revert PollContract_WrongAmountOfOptionsProvided();
        }

        Vote storage newVote = globalVotesByAddress[msg.sender][_pollId];

        for (uint256 i = 0; i < optionsVotedIds.length; i++) {
            Option storage optionVoted = pollOptions[_pollId][optionsVotedIds[i]];
            newVote.optionsVoted.push(optionVoted);
            optionVoted.numberOfVotes++;
        }

        newVote.pollId = _pollId;
        newVote.voter = msg.sender;

        pollVotes[_pollId][amountOfVotesInPoll[_pollId]] = newVote;

        amountOfVotesInPoll[_pollId]++;

        emit NewVoteInPoll(newVote);
    }

    function getPolls() public view returns (Poll[] memory) {
        Poll[] memory mPolls = new Poll[](pollsCount);
        for (uint256 i = pollsCount; i > 0; i--) {
            Poll storage sPoll = polls[i - 1];
            mPolls[i - 1] = sPoll;
        }

        return mPolls;
    }

    function getPollById(uint256 _pollId) public view returns (Poll memory, Option[] memory, uint256) {
        Option[] memory mOptions = new Option[](polls[_pollId].numberOfOptions);

        uint256 votesCount = amountOfVotesInPoll[_pollId];

        for (uint256 i = 0; i < polls[_pollId].numberOfOptions; i++) {
            Option storage sOption = pollOptions[_pollId][i];
            mOptions[i] = sOption;
        }
        return (polls[_pollId], mOptions, votesCount);
    }

    function getPollsCount() public view returns (uint256) {
        return pollsCount;
    }

    function getMyVoteInPoll(uint256 _pollId) public view returns (Vote memory) {
        return globalVotesByAddress[msg.sender][_pollId];
    }

    function getPollVotes(uint256 _pollId) public view returns (Vote[] memory) {
        uint256 votesCount = amountOfVotesInPoll[_pollId];
        Vote[] memory mVotes = new Vote[](votesCount);
        for (uint256 i = 0; i < votesCount; i++) {
            mVotes[i] = pollVotes[_pollId][i];
        }
        return mVotes;
    }
}
