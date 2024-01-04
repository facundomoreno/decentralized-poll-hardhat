// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <0.9.0;

error PollContract_NotEnoughOptionsProvided();
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
        Vote[] votes;
    }

    uint256 private pollsCount;
    // poll id and then the poll
    mapping(uint256 => Poll) private polls;
    //address is the voter and uint256 for the pollId
    mapping(address => mapping(uint256 => Vote)) private globalVotesByAddress;
    // poll id and then option id
    mapping(uint256 => mapping(uint256 => Option)) private pollOptions;

    constructor() {}

    function createPoll(
        string calldata _name,
        string calldata _description,
        bool _allowMultipleOptionsSelected,
        uint256 _closesAt,
        string[] calldata _options
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

        newPoll.numberOfOptions = 0;

        for (uint256 i = 0; i < _options.length; i++) {
            pollOptions[newPollId][i] = Option(i, newPollId, 0, _options[i]);
            newPoll.numberOfOptions++;
        }

        pollsCount++;
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

        poll.votes.push(newVote);
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
        Option[] memory mOptions = new Option[](polls[_pollId].numberOfOptions);

        for (uint256 i = 0; i < polls[_pollId].numberOfOptions; i++) {
            Option storage sOption = pollOptions[_pollId][i];
            mOptions[i] = sOption;
        }

        return mOptions;
    }

    function getMyVoteInPoll(uint256 _pollId) public view returns (Vote memory) {
        return globalVotesByAddress[msg.sender][_pollId];
    }
}
