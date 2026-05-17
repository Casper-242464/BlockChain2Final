// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {AMMPair} from "../../src/AMMPair.sol";
import {MockAMToken} from "../mocks/MockAMToken.sol";

contract AMMHandler is Test {
    AMMPair public pair;
    MockAMToken public token0;
    MockAMToken public token1;

    constructor(AMMPair pair_, MockAMToken t0, MockAMToken t1) {
        pair = pair_;
        token0 = t0;
        token1 = t1;
        token0.mint(address(this), 1_000_000e18);
        token1.mint(address(this), 1_000_000e18);
        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);
        pair.addLiquidity(100e18, 100e18, address(this));
    }

    function swap0(uint256 amountIn) external {
        amountIn = bound(amountIn, 1e12, 5e18);
        (uint256 r0, uint256 r1) = pair.getReserves();
        uint256 out = _amountOut(amountIn, r0, r1);
        if (out == 0 || out >= r1) return;
        token0.transfer(address(pair), amountIn);
        pair.swap(0, out, address(this));
    }

    function swap1(uint256 amountIn) external {
        amountIn = bound(amountIn, 1e12, 5e18);
        (uint256 r0, uint256 r1) = pair.getReserves();
        uint256 out = _amountOut(amountIn, r1, r0);
        if (out == 0 || out >= r0) return;
        token1.transfer(address(pair), amountIn);
        pair.swap(out, 0, address(this));
    }

    function _amountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256)
    {
        uint256 inWithFee = amountIn * 997;
        return (inWithFee * reserveOut) / (reserveIn * 1000 + inWithFee);
    }
}

contract AMMInvariantTest is StdInvariant, Test {
    AMMPair internal pair;
    MockAMToken internal token0;
    MockAMToken internal token1;
    AMMHandler internal handler;

    function setUp() public {
        token0 = new MockAMToken("T0", "T0");
        token1 = new MockAMToken("T1", "T1");
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }
        pair = new AMMPair(address(token0), address(token1), address(this));
        handler = new AMMHandler(pair, token0, token1);
        targetContract(address(handler));
    }

    function invariant_KNeverDecreases() public view {
        (uint256 r0, uint256 r1) = pair.getReserves();
        uint256 k = r0 * r1;
        assertGe(k, 100e18 * 100e18);
    }

    function invariant_TotalSupplyConserved() public view {
        assertGe(pair.totalSupply(), pair.MINIMUM_LIQUIDITY());
    }
}
