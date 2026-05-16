// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

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
}
