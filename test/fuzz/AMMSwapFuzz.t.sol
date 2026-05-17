// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {AMMPair} from "../../src/AMMPair.sol";
import {MockAMToken} from "../mocks/MockAMToken.sol";

/// @notice Fuzz tests for AMM swap (test-only; does not modify AMMPair.sol).
contract AMMSwapFuzzTest is Test {
    AMMPair internal pair;
    MockAMToken internal token0;
    MockAMToken internal token1;

    function setUp() public {
        token0 = new MockAMToken("T0", "T0");
        token1 = new MockAMToken("T1", "T1");
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }
        pair = new AMMPair(address(token0), address(token1), address(this));
        _addLiquidity(100e18, 100e18);
    }

    function testFuzz_SwapToken0ForToken1(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e15, 10e18);
        (uint256 reserve0Before, uint256 reserve1Before) = pair.getReserves();
        uint256 kBefore = reserve0Before * reserve1Before;

        uint256 amount1Out = _amountOut(amountIn, reserve0Before, reserve1Before);
        if (amount1Out == 0 || amount1Out >= reserve1Before) return;

        token0.mint(address(this), amountIn);
        token0.transfer(address(pair), amountIn);
        pair.swap(0, amount1Out, address(this));
        (uint256 r0, uint256 r1) = pair.getReserves();
        assertGe(r0 * r1, kBefore);
    }

    function testFuzz_SwapToken1ForToken0(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e15, 10e18);
        (uint256 reserve0, uint256 reserve1) = pair.getReserves();
        uint256 kBefore = reserve0 * reserve1;

        uint256 amount0Out = _amountOut(amountIn, reserve1, reserve0);
        if (amount0Out == 0 || amount0Out >= reserve0) return;

        token1.mint(address(this), amountIn);
        token1.transfer(address(pair), amountIn);
        pair.swap(amount0Out, 0, address(this));
        (uint256 r0, uint256 r1) = pair.getReserves();
        assertGe(r0 * r1, kBefore);
    }

    function testFuzz_QuoteMonotonic(uint256 amountA, uint256 bump) public {
        (uint256 reserve0, uint256 reserve1) = pair.getReserves();
        amountA = bound(amountA, 1, reserve0 / 10);
        bump = bound(bump, 1, reserve0 / 10);
        uint256 out1 = pair.quote(amountA, reserve0, reserve1);
        uint256 out2 = pair.quote(amountA + bump, reserve0, reserve1);
        assertGe(out2, out1);
    }

    function _addLiquidity(uint256 amount0, uint256 amount1) internal {
        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        token0.approve(address(pair), amount0);
        token1.approve(address(pair), amount1);
        pair.addLiquidity(amount0, amount1, address(this));
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
