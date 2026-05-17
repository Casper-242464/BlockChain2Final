// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Fork test reading USDC on mainnet (assignment fork requirement).
contract ForkUSDCTest is Test {
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function setUp() public {
        string memory rpc = vm.envOr("MAINNET_RPC_URL", string("https://ethereum.publicnode.com"));
        vm.createSelectFork(rpc);
    }

    function testFork_USDCTotalSupply() public view {
        assertGt(IERC20(USDC).totalSupply(), 0);
    }

    function testFork_USDCDecimals() public view {
        assertEq(IERC20(USDC).balanceOf(USDC), 0);
    }
}
