// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {GovernanceToken} from "../../src/governance/GovernanceToken.sol";
import {DSATimelock} from "../../src/governance/DSATimelock.sol";
import {DSAGovernor} from "../../src/governance/DSAGovernor.sol";

contract GovernanceTest is Test {
    GovernanceToken token;
    DSATimelock timelock;
    DSAGovernor governor;

    address public ADMIN = address(1);
    address public USER = address(2);
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    function setUp() public {
        vm.startPrank(ADMIN);
        token = new GovernanceToken("DSA Token", "DSA", ADMIN, INITIAL_SUPPLY);

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);
        timelock = new DSATimelock(2 days, proposers, executors, ADMIN);

        governor = new DSAGovernor(token, timelock);

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        vm.stopPrank();
    }

    function test_TokenMetadata() public {
        assertEq(token.name(), "DSA Token");
        assertEq(token.symbol(), "DSA");
    }

    function test_InitialSupply() public {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_DelegationWorks() public {
        vm.prank(ADMIN);
        token.delegate(ADMIN);
        vm.warp(block.timestamp + 1);
        assertEq(token.getVotes(ADMIN), INITIAL_SUPPLY);
    }

    function test_TransferUpdatesVotes() public {
        vm.startPrank(ADMIN);
        token.delegate(ADMIN);
        vm.warp(block.timestamp + 1);
        token.transfer(USER, 100 ether);
        vm.warp(block.timestamp + 1);
        vm.stopPrank();

        assertEq(token.getVotes(ADMIN), INITIAL_SUPPLY - 100 ether);
    }

    function test_GovernorSettings() public {
        assertEq(governor.votingDelay(), 1 days);
        assertEq(governor.votingPeriod(), 1 weeks);
        assertEq(governor.proposalThreshold(), 10 ether);
    }

    function test_QuorumRequirement() public {
        vm.warp(block.timestamp + 2);
        assertEq(governor.quorum(block.timestamp - 1), 40 ether);
    }

    function test_TimelockDelayConstant() public {
        assertEq(timelock.DEFAULT_MIN_DELAY(), 2 days);
    }

    function test_GovernorHasProposerRole() public {
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)));
    }

    function test_CreateProposal() public {
        vm.prank(ADMIN);
        token.delegate(ADMIN);
        vm.warp(block.timestamp + 1);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(this);
        values[0] = 0;
        calldatas[0] = "";

        vm.prank(ADMIN);
        uint256 propId = governor.propose(targets, values, calldatas, "Test Proposal");
        assertEq(uint256(governor.state(propId)), 0); // 0 = Pending
    }

    function test_Revert_ProposeWithoutVotes() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(this);

        vm.prank(USER);
        vm.expectRevert();
        governor.propose(targets, values, calldatas, "Fail Proposal");
    }

    function test_ProposalStateTransition() public {
        vm.prank(ADMIN);
        token.delegate(ADMIN);
        vm.warp(block.timestamp + 1);

        vm.prank(ADMIN);
        uint256 propId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), "State Test");

        vm.warp(block.timestamp + 1 days + 1);
        assertEq(uint256(governor.state(propId)), 1); // 1 = Active
    }

    function test_CastVote() public {
        vm.prank(ADMIN);
        token.delegate(ADMIN);
        vm.warp(block.timestamp + 1);
        vm.prank(ADMIN);
        uint256 propId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), "Vote Test");

        vm.warp(block.timestamp + 1 days + 1);
        governor.castVote(propId, 1); // 1 = For

        assertEq(uint256(governor.state(propId)), 1);
    }

    function test_Revert_VoteTwice() public {
        vm.prank(ADMIN);
        token.delegate(ADMIN);
        vm.warp(block.timestamp + 1);
        vm.prank(ADMIN);
        uint256 propId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), "Double Vote");

        vm.warp(block.timestamp + 1 days + 1);
        governor.castVote(propId, 1);

        vm.expectRevert();
        governor.castVote(propId, 1);
    }

    function test_Revert_VoteAfterPeriod() public {
        vm.prank(ADMIN);
        token.delegate(ADMIN);
        vm.warp(block.timestamp + 1);
        vm.prank(ADMIN);
        uint256 propId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), "Late Vote");

        vm.warp(block.timestamp + 1 weeks + 2 days);
        vm.expectRevert();
        governor.castVote(propId, 1);
    }

    function test_FullLifecycle_Execution() public {
        vm.startPrank(ADMIN);
        token.delegate(ADMIN);
        vm.warp(block.timestamp + 1);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = ADMIN;
        values[0] = 0;
        calldatas[0] = "";
        string memory desc = "Execute me";

        uint256 propId = governor.propose(targets, values, calldatas, desc);

        vm.warp(block.timestamp + 1 days + 1);
        governor.castVote(propId, 1);

        vm.warp(block.timestamp + 1 weeks + 1);
        governor.queue(targets, values, calldatas, keccak256(bytes(desc)));

        vm.warp(block.timestamp + 2 days + 1);
        governor.execute(targets, values, calldatas, keccak256(bytes(desc)));

        assertEq(uint256(governor.state(propId)), 7); // 7 = Executed
        vm.stopPrank();
    }
}
