// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

interface IUniswapV2Router02 {
    function factory() external view returns (address);
    function WETH() external view returns (address);
}

/// @notice Fork test touching Uniswap V2 router on mainnet.
contract ForkUniswapV2Test is Test {
    address internal constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function setUp() public {
        string memory rpc = vm.envOr("MAINNET_RPC_URL", string("https://ethereum.publicnode.com"));
        vm.createSelectFork(rpc);
    }

    function testFork_RouterFactoryNonZero() public view {
        address factory = IUniswapV2Router02(ROUTER).factory();
        assertTrue(factory != address(0));
    }

    function testFork_RouterWETH() public view {
        address weth = IUniswapV2Router02(ROUTER).WETH();
        assertTrue(weth != address(0));
    }
}
