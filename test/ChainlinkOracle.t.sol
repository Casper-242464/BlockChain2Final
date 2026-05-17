// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ChainlinkOracle} from "src/ChainlinkOracle.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

/// @notice Unit tests for ChainlinkOracle (Person 2 — gTurboflex).
contract ChainlinkOracleTest is Test {
    MockV3Aggregator internal feed;
    ChainlinkOracle internal oracle;
    uint256 internal constant STALE_SECONDS = 3600;

    function setUp() public {
        feed = new MockV3Aggregator(2_000e8);
        oracle = new ChainlinkOracle(address(feed), STALE_SECONDS);
    }

    function test_ConstructorStoresFeed() public view {
        assertEq(address(oracle.priceFeed()), address(feed));
    }

    function test_ConstructorStoresStaleness() public view {
        assertEq(oracle.stalenessPeriod(), STALE_SECONDS);
    }

    function test_ConstructorSetsOwner() public view {
        assertEq(oracle.owner(), address(this));
    }

    function test_GetLatestPriceReturnsPositive() public view {
        assertEq(oracle.getLatestPrice(), uint256(2_000e8));
    }

    function test_GetLatestPriceAfterUpdate() public {
        feed.setAnswer(3_100e8);
        assertEq(oracle.getLatestPrice(), uint256(3_100e8));
    }

    function test_Revert_InvalidPriceZero() public {
        feed.setRoundData(2, 0, block.timestamp, 2);
        vm.expectRevert(ChainlinkOracle.InvalidPrice.selector);
        oracle.getLatestPrice();
    }

    function test_Revert_InvalidPriceNegative() public {
        feed.setRoundData(2, int256(-1), block.timestamp, 2);
        vm.expectRevert(ChainlinkOracle.InvalidPrice.selector);
        oracle.getLatestPrice();
    }

    function test_Revert_StalePriceByTimestamp() public {
        vm.warp(STALE_SECONDS + 100);
        feed.setRoundData(2, 2_000e8, block.timestamp - STALE_SECONDS - 1, 2);
        vm.expectRevert(ChainlinkOracle.StalePrice.selector);
        oracle.getLatestPrice();
    }

    function test_PriceFreshWithinStalenessWindow() public {
        vm.warp(STALE_SECONDS + 100);
        feed.setRoundData(2, 2_000e8, block.timestamp - STALE_SECONDS, 2);
        assertEq(oracle.getLatestPrice(), uint256(2_000e8));
    }

    function test_Revert_StalePriceIncompleteRound() public {
        feed.setRoundData(5, 2_000e8, block.timestamp, 4);
        vm.expectRevert(ChainlinkOracle.StalePrice.selector);
        oracle.getLatestPrice();
    }

    function test_OwnerTransfer() public {
        address newOwner = makeAddr("newOwner");
        oracle.transferOwnership(newOwner);
        assertEq(oracle.owner(), newOwner);
    }

    function test_Revert_OnlyOwnerCanTransfer() public {
        vm.prank(makeAddr("stranger"));
        vm.expectRevert();
        oracle.transferOwnership(makeAddr("x"));
    }
}
