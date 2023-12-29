// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <0.9.0;

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
        PollStatus status;
        string[] options;
        Vote[] votes;
    }

    uint256 public pollsCount;
    mapping(uint256 => Poll) private polls;
    //address is the voter and uint256 for the pollId
    mapping(address => mapping(uint256 => Vote)) private globalVotesByAddress;
    mapping(uint256 => Option[]) pollOptions;

    constructor() {}

    function createPoll(
        string memory _name,
        string memory _description,
        bool _allowMultipleOptionsSelected,
        uint256 _createdAt,
        uint256 _closesAt,
        string[] memory _options
    ) external payable {
        uint256 newPollId = pollsCount++;
        Poll storage newPoll = polls[newPollId];

        newPoll.id = newPollId;
        newPoll.name = _name;
        newPoll.description = _description;
        newPoll.allowMultipleOptionsSelected = _allowMultipleOptionsSelected;
        newPoll.createdAt = _createdAt;
        newPoll.closesAt = _closesAt;
        newPoll.creator = msg.sender;
        newPoll.status = PollStatus.OPEN;
        newPoll.options = _options;
    }

    function votePoll(uint256 _pollId, uint256[] memory optionsVotedIds) external payable {
        // checking that sender did not already vote in poll
        address testAddress = globalVotesByAddress[msg.sender][_pollId].voter;
        if (testAddress == address(0)) {
            revert PollContract_AlreadyVotedInPoll();
        }

        Option[] memory mOptions = new Option[](optionsVotedIds.length);

        for (uint256 i = 0; i < optionsVotedIds.length; i++) {
            if (existsInOptions(_pollId, optionsVotedIds[i])) {
                // mOptions[mOptions.length] = pollOptions[_pollId][optionsVotedIds[i]];
            }
        }

        Vote storage newVote = globalVotesByAddress[msg.sender][_pollId];

        newVote.pollId = _pollId;
        newVote.voter = msg.sender;
        newVote.optionsVoted = mOptions;
    }

    function existsInOptions(uint256 pollId, uint256 optionId) internal view returns (bool) {
        for (uint256 i = 0; i < pollOptions[pollId].length; i++) {
            if (optionId == pollOptions[pollId][i].optionId) {
                return true;
            }
        }
        return false;
    }

    function getPolls() public view returns (Poll[] memory) {
        Poll[] memory mPolls = new Poll[](pollsCount);
        for (uint256 i = 0; i < pollsCount; i++) {
            Poll storage lBid = polls[i];
            mPolls[i] = lBid;
        }
        return mPolls;
    }

    function getPollById(uint256 _pollId) public view returns (Poll memory) {
        return polls[_pollId];
    }

    function getPollsCount() public view returns (uint256) {
        return pollsCount;
    }
}
