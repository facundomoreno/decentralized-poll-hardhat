// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <0.9.0;

contract PollContract {
    enum PollStatus {
        OPEN,
        CLOSED
    }

    struct Option {
        uint256 optionNumber;
        string name;
    }

    struct Vote {
        Option[] optionsVoted;
        address voter;
    }

    struct Poll {
        uint256 id;
        string name;
        string description;
        uint256 createdAt;
        uint256 closesAt;
        address creator;
        address payable[] voters;
        PollStatus status;
        Vote[] votes;
    }

    constructor() {}
}
