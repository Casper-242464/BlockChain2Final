// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Vulnerable: anyone can mint (before fix).
contract VulnerableMinter {
    mapping(address => uint256) public balances;

    function mint(address to, uint256 amount) external {
        balances[to] += amount;
    }
}

/// @dev Fixed with OpenZeppelin Ownable.
contract FixedMinter is Ownable {
    mapping(address => uint256) public balances;

    constructor(address owner_) Ownable(owner_) {}

    function mint(address to, uint256 amount) external onlyOwner {
        balances[to] += amount;
    }
}

contract AccessControlCaseStudyTest is Test {
    address internal admin = makeAddr("admin");
    address internal attacker = makeAddr("attacker");

    function test_VulnerableMinter_AnyoneCanMint() public {
        VulnerableMinter minter = new VulnerableMinter();
        vm.prank(attacker);
        minter.mint(attacker, 1_000 ether);
        assertEq(minter.balances(attacker), 1_000 ether);
    }

    function test_FixedMinter_OnlyOwnerCanMint() public {
        FixedMinter minter = new FixedMinter(admin);
        vm.prank(admin);
        minter.mint(admin, 500 ether);
        assertEq(minter.balances(admin), 500 ether);
    }

    function test_FixedMinter_RevertWhenNotOwner() public {
        FixedMinter minter = new FixedMinter(admin);
        vm.prank(attacker);
        vm.expectRevert();
        minter.mint(attacker, 1 ether);
    }

    function test_FixedMinter_OwnershipTransfer() public {
        FixedMinter minter = new FixedMinter(admin);
        address newAdmin = makeAddr("newAdmin");
        vm.prank(admin);
        minter.transferOwnership(newAdmin);
        vm.prank(newAdmin);
        minter.mint(newAdmin, 1 ether);
        assertEq(minter.balances(newAdmin), 1 ether);
    }
}
