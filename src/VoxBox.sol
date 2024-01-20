// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VoxBox {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint voteCount;
    }

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    address public owner;
    mapping(address => Voter) public voters;
    mapping(uint => Candidate) public candidates;
    mapping(string => bool) private candidateNames;
    uint public candidatesCount;
    uint public totalVotes;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerVoter() public {
        require(!voters[msg.sender].isRegistered, "Voter is already registered");
        voters[msg.sender] = Voter(true, false, 0);
    }

    function addCandidate(string memory _name) public onlyOwner {
        require(!candidateNames[_name], "Candidate name already used");
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        candidateNames[_name] = true;
    }

    function getTotalVotes() public view returns (uint) {
        return totalVotes;
    }

}
