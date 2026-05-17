// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

/// @dev Intentionally vulnerable: external call before state update (before fix).
contract VulnerableVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "balance");
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "send");
        balances[msg.sender] -= amount;
    }
}

/// @dev Fixed: checks-effects-interactions + reentrancy guard (after fix).
contract FixedVault {
    mapping(address => uint256) public balances;
    uint256 private locked;

    modifier nonReentrant() {
        require(locked == 0, "reentrant");
        locked = 1;
        _;
        locked = 0;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "balance");
        balances[msg.sender] -= amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "send");
    }
}

contract ReentrancyExploiter {
    VulnerableVault public immutable vault;
    bool public entered;

    constructor(VulnerableVault vault_) {
        vault = vault_;
    }

    function run() external payable {
        vault.deposit{value: 1 ether}();
        vault.withdraw(1 ether);
    }

    receive() external payable {
        if (!entered) {
            entered = true;
        }
    }
}

contract ReentrancyBlocker {
    FixedVault public immutable vault;

    constructor(FixedVault vault_) {
        vault = vault_;
    }

    function run() external payable {
        vault.deposit{value: 1 ether}();
        vault.withdraw(1 ether);
    }

    receive() external payable {
        vault.withdraw(1 ether);
    }
}

/// @notice Reentrancy case study — before/after (Person 2 — gTurboflex).
contract ReentrancyCaseStudyTest is Test {
    receive() external payable {}

    function test_VulnerableVault_CallbackBeforeBalanceUpdate() public {
        VulnerableVault vault = new VulnerableVault();
        ReentrancyExploiter exploiter = new ReentrancyExploiter(vault);

        vm.deal(address(exploiter), 1 ether);
        exploiter.run{value: 1 ether}();

        assertTrue(exploiter.entered(), "receive hook ran during withdraw (CEI violation window)");
    }

    function test_FixedVault_BlocksReentrancy() public {
        FixedVault vault = new FixedVault();
        ReentrancyBlocker blocker = new ReentrancyBlocker(vault);

        vm.deal(address(blocker), 1 ether);
        vm.expectRevert();
        blocker.run{value: 1 ether}();
    }

    function test_FixedVault_HonestWithdraw() public {
        FixedVault vault = new FixedVault();
        vm.deal(address(this), 2 ether);
        vault.deposit{value: 1 ether}();
        vault.withdraw(0.4 ether);
        assertEq(vault.balances(address(this)), 0.6 ether);
    }
}
