// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {AMMPair} from "../../src/AMMPair.sol";
import {MockAMToken} from "../mocks/MockAMToken.sol";

contract AMMPairTest is Test {
    AMMPair internal pair;
    MockAMToken internal token0;
    MockAMToken internal token1;
    address internal user = makeAddr("user");

    function setUp() public {
        token0 = new MockAMToken("AAA", "AAA");
        token1 = new MockAMToken("BBB", "BBB");
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }
        pair = new AMMPair(address(token0), address(token1), address(this));
    }

    function test_TokenOrdering() public view {
        assertTrue(address(pair.token0()) < address(pair.token1()));
    }

    function test_InitialReservesZero() public view {
        (uint256 r0, uint256 r1) = pair.getReserves();
        assertEq(r0, 0);
        assertEq(r1, 0);
    }

    function test_FirstMintLocksMinimumLiquidity() public {
        _mintTokens(user, 100e18, 100e18);
        vm.startPrank(user);
        token0.approve(address(pair), 100e18);
        token1.approve(address(pair), 100e18);
        uint256 liquidity = pair.addLiquidity(100e18, 100e18, user);
        vm.stopPrank();
        assertGt(liquidity, 0);
        assertEq(pair.totalSupply(), liquidity + pair.MINIMUM_LIQUIDITY());
        assertEq(pair.balanceOf(address(0)), pair.MINIMUM_LIQUIDITY());
    }

    function test_AddLiquidityUpdatesReserves() public {
        _bootstrapLiquidity();
        (uint256 r0, uint256 r1) = pair.getReserves();
        assertGt(r0, 0);
        assertGt(r1, 0);
    }

    function test_RemoveLiquidityReturnsTokens() public {
        _bootstrapLiquidity();
        uint256 lp = pair.balanceOf(user);
        uint256 burn = lp / 4;
        vm.prank(user);
        (uint256 a0, uint256 a1) = pair.removeLiquidity(burn, user);
        assertGt(a0, 0);
        assertGt(a1, 0);
    }

    function test_SwapToken0InIncreasesK() public {
        _bootstrapLiquidity();
        (uint256 r0, uint256 r1) = pair.getReserves();
        uint256 kBefore = r0 * r1;

        uint256 amountIn = 1e18;
        uint256 amount1Out = _getAmountOut(amountIn, r0, r1);

        token0.mint(address(this), amountIn);
        token0.transfer(address(pair), amountIn);
        pair.swap(0, amount1Out, address(this));

        (uint256 r0After, uint256 r1After) = pair.getReserves();
        assertGe(r0After * r1After, kBefore);
    }

    function test_SwapToken1InIncreasesK() public {
        _bootstrapLiquidity();
        (uint256 r0, uint256 r1) = pair.getReserves();
        uint256 kBefore = r0 * r1;

        uint256 amountIn = 1e18;
        uint256 amount0Out = _getAmountOut(amountIn, r1, r0);

        token1.mint(address(this), amountIn);
        token1.transfer(address(pair), amountIn);
        pair.swap(amount0Out, 0, address(this));

        (uint256 r0After, uint256 r1After) = pair.getReserves();
        assertGe(r0After * r1After, kBefore);
    }

    function test_QuoteRevertsOnZeroAmount() public {
        _bootstrapLiquidity();
        (uint256 r0, uint256 r1) = pair.getReserves();
        vm.expectRevert();
        pair.quote(0, r0, r1);
    }

    function test_Revert_SwapInsufficientOutput() public {
        _bootstrapLiquidity();
        vm.expectRevert();
        pair.swap(0, 0, address(this));
    }

    function test_Revert_AddLiquidityZero() public {
        vm.expectRevert();
        pair.addLiquidity(0, 1, user);
    }

    function test_Revert_RemoveZeroLiquidity() public {
        _bootstrapLiquidity();
        vm.prank(user);
        vm.expectRevert();
        pair.removeLiquidity(0, user);
    }

    function test_ApproveTransferLP() public {
        _bootstrapLiquidity();
        uint256 amount = pair.balanceOf(user) / 10;
        vm.prank(user);
        pair.approve(address(this), amount);
        pair.transferFrom(user, address(this), amount);
        assertEq(pair.balanceOf(address(this)), amount);
    }

    function test_TransferLP() public {
        _bootstrapLiquidity();
        address recipient = makeAddr("recipient");
        uint256 amount = 500;
        vm.prank(user);
        pair.transfer(recipient, amount);
        assertEq(pair.balanceOf(recipient), amount);
    }

    function test_Revert_TransferExceedsBalance() public {
        _bootstrapLiquidity();
        vm.prank(user);
        vm.expectRevert();
        pair.transfer(makeAddr("x"), type(uint256).max);
    }

    function test_Revert_SwapInvalidTo() public {
        _bootstrapLiquidity();
        vm.expectRevert();
        pair.swap(1, 0, address(0));
    }

    function _bootstrapLiquidity() internal {
        _mintTokens(user, 50e18, 50e18);
        vm.startPrank(user);
        token0.approve(address(pair), 50e18);
        token1.approve(address(pair), 50e18);
        pair.addLiquidity(50e18, 50e18, user);
        vm.stopPrank();
    }

    function _mintTokens(address to, uint256 a0, uint256 a1) internal {
        token0.mint(to, a0);
        token1.mint(to, a1);
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256)
    {
        uint256 amountInWithFee = amountIn * 997;
        return (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
    }
}
