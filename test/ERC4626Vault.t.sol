// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626Vault} from "../src/ERC4626Vault.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {ERC4626Test} from "erc4626-tests/ERC4626.test.sol";

/// @notice OpenZeppelin ERC-4626 rounding / invariant property suite for our vault.
contract ERC4626VaultPropTest is ERC4626Test {
    MockERC20 internal underlying;
    ERC4626Vault internal vault;

    function setUp() public override {
        underlying = new MockERC20("Underlying", "UND", 18);
        vault = new ERC4626Vault(IERC20(address(underlying)), "Yield Vault", "yvUND");
        _underlying_ = address(underlying);
        _vault_ = address(vault);
        _vaultMayBeEmpty = false;
        _unlimitedAmount = false;
        _delta_ = 0;
    }
}

/// @notice Unit tests for ERC4626Vault-specific behavior (Person 2 — gTurboflex).
contract ERC4626VaultUnitTest is Test {
    MockERC20 internal asset;
    ERC4626Vault internal vault;
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        asset = new MockERC20("Asset", "AST", 18);
        vault = new ERC4626Vault(IERC20(address(asset)), "Vault Shares", "vAST");
    }

    function test_ConstructorSetsAsset() public view {
        assertEq(vault.asset(), address(asset));
    }

    function test_ConstructorSetsOwner() public view {
        assertEq(vault.owner(), address(this));
    }

    function test_NameAndSymbol() public view {
        assertEq(vault.name(), "Vault Shares");
        assertEq(vault.symbol(), "vAST");
    }

    function test_TotalAssetsEmpty() public view {
        assertEq(vault.totalAssets(), 0);
    }

    function test_Revert_FirstDepositBelowMinimum() public {
        asset.mint(alice, 1000);
        vm.startPrank(alice);
        asset.approve(address(vault), 1000);
        vm.expectRevert(ERC4626Vault.DepositTooLow.selector);
        vault.deposit(999, alice);
        vm.stopPrank();
    }

    function test_FirstDepositAtMinimum() public {
        asset.mint(alice, 10_000);
        vm.startPrank(alice);
        asset.approve(address(vault), 10_000);
        uint256 shares = vault.deposit(1000, alice);
        vm.stopPrank();
        assertGt(shares, 0);
        assertEq(vault.balanceOf(alice), shares);
        assertEq(vault.totalAssets(), 1000);
    }

    function test_Revert_FirstMintBelowMinimum() public {
        asset.mint(alice, 10_000);
        vm.startPrank(alice);
        asset.approve(address(vault), 10_000);
        vm.expectRevert(ERC4626Vault.DepositTooLow.selector);
        vault.mint(1, alice);
        vm.stopPrank();
    }

    function test_SecondDepositIgnoresMinimum() public {
        _seedVault(alice, 1000);
        asset.mint(alice, 500);
        vm.startPrank(alice);
        asset.approve(address(vault), 500);
        vault.deposit(1, alice);
        vm.stopPrank();
        assertEq(vault.totalAssets(), 1001);
    }

    function test_DepositMintsShares() public {
        _seedVault(alice, 5000);
        asset.mint(bob, 2000);
        vm.startPrank(bob);
        asset.approve(address(vault), 2000);
        uint256 shares = vault.deposit(2000, bob);
        vm.stopPrank();
        assertEq(vault.balanceOf(bob), shares);
        assertEq(vault.totalAssets(), 7000);
    }

    function test_WithdrawBurnsShares() public {
        _seedVault(alice, 10_000);
        uint256 sharesBefore = vault.balanceOf(alice);
        vm.prank(alice);
        uint256 assets = vault.withdraw(3000, alice, alice);
        assertEq(assets, 3000);
        assertLt(vault.balanceOf(alice), sharesBefore);
    }

    function test_RedeemReturnsAssets() public {
        _seedVault(alice, 10_000);
        uint256 shares = vault.balanceOf(alice) / 2;
        vm.prank(alice);
        uint256 assets = vault.redeem(shares, alice, alice);
        assertGt(assets, 0);
        assertLt(vault.totalAssets(), 10_000);
    }

    function test_MintChargesAssets() public {
        _seedVault(alice, 5000);
        asset.mint(bob, 5000);
        vm.startPrank(bob);
        asset.approve(address(vault), 5000);
        uint256 assets = vault.mint(1000, bob);
        vm.stopPrank();
        assertGt(assets, 0);
        assertEq(vault.balanceOf(bob), 1000);
    }

    function test_ConvertToSharesEmptyVault() public view {
        assertEq(vault.convertToShares(1000), 1000);
    }

    function test_ConvertToAssetsAfterDeposit() public {
        _seedVault(alice, 4000);
        uint256 shares = vault.balanceOf(alice);
        assertEq(vault.convertToAssets(shares), 4000);
    }

    function test_PreviewDepositMatchesDeposit() public {
        _seedVault(alice, 1000);
        asset.mint(bob, 2000);
        vm.startPrank(bob);
        asset.approve(address(vault), 2000);
        uint256 expected = vault.previewDeposit(1500);
        uint256 shares = vault.deposit(1500, bob);
        vm.stopPrank();
        assertEq(shares, expected);
    }

    function test_MaxDepositUnlimitedForReceiver() public {
        _seedVault(alice, 1000);
        assertEq(vault.maxDeposit(bob), type(uint256).max);
    }

    function test_MaxWithdrawAfterDeposit() public {
        _seedVault(alice, 2500);
        assertEq(vault.maxWithdraw(alice), 2500);
    }

    function test_MaxRedeemAfterDeposit() public {
        _seedVault(alice, 2500);
        assertEq(vault.maxRedeem(alice), vault.balanceOf(alice));
    }

    function test_TransferSharesBetweenUsers() public {
        _seedVault(alice, 5000);
        uint256 half = vault.balanceOf(alice) / 2;
        vm.prank(alice);
        vault.transfer(bob, half);
        assertEq(vault.balanceOf(bob), half);
    }

    function test_ApproveAndTransferFrom() public {
        _seedVault(alice, 5000);
        uint256 amount = 1000;
        vm.prank(alice);
        vault.approve(bob, amount);
        vm.prank(bob);
        vault.transferFrom(alice, bob, amount);
        assertEq(vault.balanceOf(bob), amount);
    }

    function test_Revert_WithdrawMoreThanBalance() public {
        _seedVault(alice, 1000);
        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(2000, alice, alice);
    }

    function test_Revert_RedeemMoreThanShares() public {
        _seedVault(alice, 1000);
        uint256 tooMany = vault.balanceOf(alice) + 1;
        vm.prank(alice);
        vm.expectRevert();
        vault.redeem(tooMany, alice, alice);
    }

    function test_YieldIncreasesShareValue() public {
        _seedVault(alice, 10_000);
        asset.mint(address(vault), 1000);
        assertEq(vault.totalAssets(), 11_000);
        uint256 assetsPerShare = vault.convertToAssets(1e18);
        assertGt(assetsPerShare, 1e18);
    }

    function _seedVault(address user, uint256 assets) internal {
        asset.mint(user, assets);
        vm.startPrank(user);
        asset.approve(address(vault), assets);
        vault.deposit(assets, user);
        vm.stopPrank();
    }
}
