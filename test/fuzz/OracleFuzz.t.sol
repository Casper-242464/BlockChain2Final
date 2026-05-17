// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ChainlinkOracle} from "../../src/ChainlinkOracle.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract OracleFuzzTest is Test {
    function testFuzz_FreshPriceWithinWindow(uint256 staleness, uint256 age) public {
        staleness = bound(staleness, 1, 7 days);
        age = bound(age, 0, staleness);
        vm.warp(30 days);

        MockV3Aggregator feed = new MockV3Aggregator(int256(1e8));
        ChainlinkOracle oracle = new ChainlinkOracle(address(feed), staleness);

        feed.setRoundData(1, int256(1e8), block.timestamp - age, 1);
        assertEq(oracle.getLatestPrice(), uint256(1e8));
    }

    function testFuzz_RevertWhenOlderThanStaleness(uint256 staleness, uint256 age) public {
        staleness = bound(staleness, 60, 3 days);
        age = bound(age, staleness + 1, staleness + 1 days);
        vm.warp(30 days);

        MockV3Aggregator feed = new MockV3Aggregator(int256(2e8));
        ChainlinkOracle oracle = new ChainlinkOracle(address(feed), staleness);

        feed.setRoundData(2, int256(2e8), block.timestamp - age, 2);
        vm.expectRevert(ChainlinkOracle.StalePrice.selector);
        oracle.getLatestPrice();
    }

    function testFuzz_PositivePriceAccepted(int256 price) public {
        price = int256(bound(uint256(price), 1, type(uint128).max));
        MockV3Aggregator feed = new MockV3Aggregator(price);
        ChainlinkOracle oracle = new ChainlinkOracle(address(feed), 1 hours);
        assertEq(oracle.getLatestPrice(), uint256(price));
    }
}
