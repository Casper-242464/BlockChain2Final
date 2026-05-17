// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {GovernanceToken} from "src/governance/GovernanceToken.sol";

/// @notice Fuzz voting power updates (assignment: governance voting power fuzz).
contract GovernanceVotesFuzzTest is Test {
    GovernanceToken internal token;
    address internal holder = makeAddr("holder");

    function setUp() public {
        token = new GovernanceToken("Gov", "GOV", address(this), 1_000_000 ether);
        token.transfer(holder, 500_000 ether);
        vm.prank(holder);
        token.delegate(holder);
        vm.warp(block.timestamp + 1);
    }

    function testFuzz_DelegatedVotesMatchBalance(uint256 transferAmount) public {
        transferAmount = bound(transferAmount, 1, 100_000 ether);
        address recipient = makeAddr("recipient");
        vm.prank(holder);
        token.transfer(recipient, transferAmount);
        vm.warp(block.timestamp + 1);
        assertEq(token.getVotes(holder), 500_000 ether - transferAmount);
    }

    function testFuzz_DelegateUpdatesCheckpoint(address delegatee) public {
        vm.assume(delegatee != address(0));
        vm.prank(holder);
        token.delegate(delegatee);
        vm.warp(block.timestamp + 1);
        assertEq(token.getVotes(delegatee), 500_000 ether);
    }
}
