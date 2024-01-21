//SPDX-License-Identifier:MIT 

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/VoxBox.sol";

contract VoxBoxTest is Test {
    VoxBox voxBox;
    address owner;
    address voter1;
    address voter2;
    address voter3;
    address voter4;

    function setUp() public {
        owner = address(this); // Test contract is the owner
        voxBox = new VoxBox();
        vm.startPrank(owner);
        voxBox.setVotingPeriod(uint32(block.timestamp), uint32(block.timestamp + 1 weeks));
        vm.stopPrank();

        voter1 = address(0x1);
        voter2 = address(0x2);
    }

    function registerVoter(address voter) internal {
        vm.prank(voter);
        voxBox.registerVoter();
    }

    function addCandidate(string memory name) internal {
        vm.prank(owner);
        voxBox.addCandidate(name);
    }

    function vote(address voter, uint256 candidateId) internal {
        vm.prank(voter);
        voxBox.vote(candidateId);
    }

    function testSetVotingPeriod() public {
        uint32 newStartTime = uint32(block.timestamp);
        uint32 newEndTime = uint32(block.timestamp + 2 weeks);

        // Valid voting period set
        vm.prank(owner);
        voxBox.setVotingPeriod(newStartTime, newEndTime);

        assertEq(voxBox.startTime(), newStartTime, "Start time should be updated");
        assertEq(voxBox.endTime(), newEndTime, "End time should be updated");

        // Invalid voting period (end time before start time)
        vm.expectRevert("Start time must be before end time");
        vm.prank(owner);
        voxBox.setVotingPeriod(newEndTime, newStartTime);

        // Non-owner trying to set voting period
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(voter1);
        voxBox.setVotingPeriod(newStartTime, newEndTime);
    }

    function testRegisterVoter() public {
        // Voter registration during voting period
        vm.prank(voter1);
        voxBox.registerVoter();
        assertTrue(voxBox.getVoters(voter1).isRegistered, "Voter1 should be registered");

        // Double registration by the same voter
        bytes4 customError1=bytes4(keccak256("Vox__VoterAlreadyRegistered()"));
        vm.expectRevert(customError1);
        vm.prank(voter1);
        voxBox.registerVoter();

        // Voter registration outside voting period
        vm.warp(block.timestamp + 2 weeks); // Fast-forward time beyond the voting period
        bytes4 customError2=bytes4(keccak256("Vox__VotingNotActive()"));
        vm.expectRevert(customError2);
        vm.prank(voter2);
        voxBox.registerVoter();
    }
    function testAddCandidate() public {
        // Add a new candidate by the owner
        string memory candidateName = "Alice";
        addCandidate(candidateName);
        VoxBox.Candidate memory addedCandidate = voxBox.getCandidate(1);
        assertEq(addedCandidate.name, candidateName, "Candidate name should match");

        // Add a duplicate candidate
        bytes4 customError1=bytes4(keccak256("Vox__CandidateAlreadyExists()"));
        vm.expectRevert(customError1);
        addCandidate(candidateName);

        // Add a candidate by a non-owner account
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(voter1);
        voxBox.addCandidate("Bob");
    }

    function testFailDelegateVote() public {
        registerVoter(voter1);
        registerVoter(voter2);
        addCandidate("Alice");

        // Delegate vote to a registered voter
        vm.prank(voter1);
        voxBox.delegateVote(voter2);

        // Delegate by an unregistered voter
        bytes4 customError1=bytes4(keccak256("Vox__MustBeRegisteredVoter()"));
        vm.expectRevert(customError1);
        vm.prank(address(0x3)); // Unregistered voter
        voxBox.delegateVote(voter2);

        // Delegate after having voted
        vote(voter1, 1);
        bytes4 customError2=bytes4(keccak256("Vox__VoterAlreadyVoted()"));
        vm.expectRevert(customError2);
        vm.prank(voter1);
        voxBox.delegateVote(voter2);

        // Delegate to an unregistered voter
        bytes4 customError3=bytes4(keccak256("Vox__DelegateNotRegisteredVoter()"));
        vm.expectRevert(customError3);
        vm.prank(voter2);
        voxBox.delegateVote(address(0x3)); // Unregistered voter
    }

    function testVote() public {
        registerVoter(voter1);
        addCandidate("Alice");

        // Valid vote
        vote(voter1, 1);
        assertEq(voxBox.getCandidates(1).voteCount, 1, "Candidate should have 1 vote");

        // Voting by an unregistered voter
        bytes4 customError1=bytes4(keccak256("Vox__MustBeRegisteredVoter()"));
        vm.expectRevert(customError1);
        vm.prank(address(0x3)); // Unregistered voter
        voxBox.vote(1);

        // Voting for an invalid candidate ID
        bytes4 customError2=bytes4(keccak256("Vox__InvalidCandidateID()"));
        vm.expectRevert(customError2);
        vm.prank(voter1);
        voxBox.vote(999); // Non-existent candidate

        // Double voting by the same voter
        bytes4 customError3=bytes4(keccak256("Vox__VoterAlreadyVoted()"));
        vm.expectRevert(customError3);
        vm.prank(voter1);
        voxBox.vote(1);
    }

    function testSelectingSingleWinner() public {
        registerVoter(voter1);
        registerVoter(voter2);
        registerVoter(voter3);

        addCandidate("Alice");
        addCandidate("Bob");

        vote(voter1, 1); // Alice receives one vote
        vote(voter2, 2); // Bob receives one vote
        vote(voter3, 2); // Bob receives another vote, now leading

        VoxBox.Candidate[] memory winners = voxBox.getWinners();
        assertEq(winners.length, 1, "There should be one winner");
        assertEq(winners[0].id, 2, "Winner should be candidate 2 (Bob)");
        assertEq(winners[0].name, "Bob", "Winner's name should be Bob");
    }
    function testSelectingWinnersInCaseOfTie() public {
        registerVoter(voter1);
        registerVoter(voter2);

        addCandidate("Alice");
        addCandidate("Bob");

        vote(voter1, 1); // Alice receives one vote
        vote(voter2, 2); // Bob receives one vote

        VoxBox.Candidate[] memory winners = voxBox.getWinners();
        assertEq(winners.length, 2, "There should be two winners in a tie");
        assertEq(winners[0].id, 1, "First winner should be candidate 1 (Alice)");
        assertEq(winners[1].id, 2, "Second winner should be candidate 2 (Bob)");
    }
    function testSelectingWinnersWithNoVotes() public {
        testSelectingSingleWinner();

        VoxBox.Candidate[] memory winners = voxBox.getWinners();
        assertEq(winners.length, 1, "There should be no winners if no votes are cast");
    }


}
