// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ChainlinkOracle} from "../../src/ChainlinkOracle.sol";

/// @notice Fork test against live Chainlink ETH/USD feed on Ethereum mainnet.
contract ForkChainlinkTest is Test {
    address internal constant ETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    function setUp() public {
        string memory rpc = vm.envOr("MAINNET_RPC_URL", string("https://ethereum.publicnode.com"));
        vm.createSelectFork(rpc);
    }

    function testFork_MainnetEthUsdFeedFresh() public {
        ChainlinkOracle oracle = new ChainlinkOracle(ETH_USD_FEED, 24 hours);
        uint256 price = oracle.getLatestPrice();
        assertGt(price, 0);
    }

    function testFork_RevertWhenStalenessTooTight() public {
        ChainlinkOracle oracle = new ChainlinkOracle(ETH_USD_FEED, 1);
        vm.expectRevert(ChainlinkOracle.StalePrice.selector);
        oracle.getLatestPrice();
    }
}
