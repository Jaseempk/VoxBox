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

import "@openzeppelin/contracts/access/Ownable.sol";

//Errors
error Vox__VotingNotActive();
error Vox__VoterAlreadyRegistered();
error Vox__CandidateAlreadyExists();
error Vox__InvalidCandidateID();
error Vox__MustBeRegisteredVoter();
error Vox__VoterAlreadyVoted();
error Vox__DelegateNotRegisteredVoter();

/**
 * @title VoxBox: Decentralized Voting System
 * @dev Implements a simple yet efficient voting system. Features include voter registration, candidate addition,
 *      voting, and vote delegation, with a focus on security and gas efficiency.
 *
 * Features and Approach:
 * - Voting is restricted to a specified period, and only the contract owner can add candidates.
 * - Voters can either vote for candidates or delegate their votes.
 * - Utilizes dynamic tracking of leading candidates to efficiently determine winners.
 * - Employs custom errors for better clarity and gas savings over traditional `require` statements.
 * - Inherits OpenZeppelin's Ownable for reliable ownership management.
 *
 * @notice Designed for basic voting scenarios; not suited for complex electoral systems or anonymous voting.
 */
contract VoxBox is Ownable{

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedCandidateId;
        address delegate;
    }

    struct Candidate {
        uint256 id;
        string name;
        uint16 voteCount;
    }

    uint256 public candidatesCount;
    uint32 public startTime;
    uint32 public endTime;
    uint16 public totalVotes;
    uint16 private highestVoteCount;
    uint256[] private leadingCandidates;

    mapping(address => Voter) public voters;
    mapping(uint256 => Candidate) public candidates;
    mapping(string => bool) private candidateExists;

    event VoterRegistered(address voter);
    event VoteDelegated(address from, address to);
    event CandidateAdded(uint256 candidateId, string candidateName);
    event VoteCasted(address voter, uint256 candidateId);
    event VotingPeriodSet(uint256 startTime, uint256 endTime);
    event WinnerSelected(Candidate[] winner);

    /// @dev Modifier to restrict function access to the active voting period.
    modifier duringVotingPeriod() {
        if (block.timestamp < startTime || block.timestamp > endTime) revert Vox__VotingNotActive();
        _;
    }

    constructor()Ownable(msg.sender) {
    }

    /// @notice Sets the voting period.
    /// @param _startTime The start time of the voting period as a UNIX timestamp.
    /// @param _endTime The end time of the voting period as a UNIX timestamp.
    function setVotingPeriod(uint32 _startTime, uint32 _endTime) public onlyOwner {
        require(_startTime < _endTime, "Start time must be before end time");
        startTime = _startTime;
        endTime = _endTime;
        emit VotingPeriodSet(_startTime, _endTime);
    }

    /// @notice Registers a voter for the voting period.
    /// @dev Emits the VoterRegistered event upon successful registration.
    function registerVoter() public duringVotingPeriod {
        if (voters[msg.sender].isRegistered) revert Vox__VoterAlreadyRegistered();
        voters[msg.sender].isRegistered = true;
        emit VoterRegistered(msg.sender);
    }

    /// @notice Adds a new candidate to the election.
    /// @dev Emits the CandidateAdded event upon successful addition of the candidate.
    /// @param _name The name of the candidate to be added.
    function addCandidate(string memory _name) public onlyOwner {
        if (candidateExists[_name]) revert Vox__CandidateAlreadyExists();
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        candidateExists[_name] = true;
        emit CandidateAdded(candidatesCount, _name);
    }

    /// @notice Delegates a voter's vote to another registered voter.
    /// @dev Emits the VoteDelegated event upon successful delegation.
    /// @param _delegate The address of the voter to whom the vote is being delegated.
    function delegateVote(address _delegate) public duringVotingPeriod {
        if (!voters[msg.sender].isRegistered) revert Vox__MustBeRegisteredVoter();
        if (voters[msg.sender].hasVoted) revert Vox__VoterAlreadyVoted();
        if (!voters[_delegate].isRegistered) revert Vox__DelegateNotRegisteredVoter();

        voters[msg.sender].hasVoted = true;
        if (voters[_delegate].hasVoted) {
            candidates[voters[_delegate].votedCandidateId].voteCount++;
        } else {
            voters[_delegate].delegate = msg.sender;
            emit VoteDelegated(msg.sender, _delegate);
        }
    }

    /// @notice Allows a registered voter to cast their vote for a candidate.
    /// @dev Updates the vote count for the candidate and checks for potential leading candidates.
    /// @param _candidateId The unique identifier of the candidate.
    function vote(uint256 _candidateId) public duringVotingPeriod {
        if (!voters[msg.sender].isRegistered) revert Vox__MustBeRegisteredVoter();
        if (voters[msg.sender].hasVoted) revert Vox__VoterAlreadyVoted();
        if (_candidateId == 0 || _candidateId > candidatesCount) revert Vox__InvalidCandidateID();

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedCandidateId = _candidateId;
        candidates[_candidateId].voteCount++;
        totalVotes++;

        // Update leading candidates
        if (candidates[_candidateId].voteCount > highestVoteCount) {
            highestVoteCount = candidates[_candidateId].voteCount;
            delete leadingCandidates;
            leadingCandidates.push(_candidateId);
        } else if (candidates[_candidateId].voteCount == highestVoteCount) {
            leadingCandidates.push(_candidateId);
        }


        emit VoteCasted(msg.sender, _candidateId);
    }

    /// @notice Retrieves the winners of the voting contest.
    /// @dev Returns an array of candidates with the highest vote count.
    /// @return winners Array of candidates who have won the voting contest.
    function getWinners() public  returns (Candidate[] memory) {
        Candidate[] memory winners = new Candidate[](leadingCandidates.length);
        for (uint256 i = 0; i < leadingCandidates.length; i++) {
            winners[i] = candidates[leadingCandidates[i]];
        }
        emit WinnerSelected(winners);
        return winners;
    }
    /**

     * 
     */

    /// @notice Retrieves details of a specific candidate.
    /// @param _candidateId The unique identifier of the candidate.
    /// @return Candidate details including id, name, and vote count.
    function getCandidate(uint256 _candidateId) public view returns (Candidate memory) {
        if (_candidateId == 0 || _candidateId > candidatesCount) revert Vox__InvalidCandidateID();
        return candidates[_candidateId];
    }

    /// @notice Returns the total number of votes cast in the election.
    /// @return The total vote count.
    function getTotalVotes() public view returns (uint256) {
        return totalVotes;
    }

    /// @notice Retrieves a list of all candidates in the election.
    /// @return An array of all candidates.
    function getCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory allCandidates = new Candidate[](candidatesCount);
        for (uint256 i = 1; i <= candidatesCount; i++) {
            allCandidates[i - 1] = candidates[i];
        }
        return allCandidates;
    }
    /// 
    /// @param voter address of the voter whose details we are trying to access
    function getVoters(address voter) public view returns(Voter memory){
        return voters[voter];
    }
    function getCandidates(uint256 candidateId)public view returns(Candidate memory){
        return candidates[candidateId];
    }
}
