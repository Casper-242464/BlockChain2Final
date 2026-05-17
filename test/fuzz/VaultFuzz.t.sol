// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626Vault} from "../../src/ERC4626Vault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract VaultFuzzTest is Test {
    MockERC20 internal asset;
    ERC4626Vault internal vault;

    function setUp() public {
        asset = new MockERC20("AST", "AST", 18);
        vault = new ERC4626Vault(IERC20(address(asset)), "vAST", "vAST");
        asset.mint(address(this), 1_000_000e18);
        asset.approve(address(vault), type(uint256).max);
        vault.deposit(1000, address(this));
    }

    function testFuzz_DepositWithdrawRoundTrip(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1, 100_000e18);
        withdrawAmount = bound(withdrawAmount, 1, depositAmount);

        uint256 shares = vault.deposit(depositAmount, address(this));
        assertGt(shares, 0);

        uint256 assetsOut = vault.withdraw(withdrawAmount, address(this), address(this));
        assertEq(assetsOut, withdrawAmount);
        assertGe(vault.totalAssets(), vault.totalSupply());
    }

    function testFuzz_MintRedeemRoundTrip(uint256 shares) public {
        shares = bound(shares, 1, 50_000e18);
        uint256 assetsIn = vault.mint(shares, address(this));
        assertGt(assetsIn, 0);

        uint256 assetsOut = vault.redeem(shares, address(this), address(this));
        assertApproxEqAbs(assetsOut, assetsIn, 1);
    }

    function testFuzz_ConvertRoundTrip(uint256 assets) public {
        assets = bound(assets, 1, 1_000_000e18);
        uint256 shares = vault.convertToShares(assets);
        uint256 back = vault.convertToAssets(shares);
        assertApproxEqAbs(back, assets, 1);
    }

    function testFuzz_PreviewDepositMatches(uint256 assets) public {
        assets = bound(assets, 1, 500_000e18);
        uint256 expected = vault.previewDeposit(assets);
        uint256 minted = vault.deposit(assets, address(this));
        assertEq(minted, expected);
    }

    function testFuzz_TotalAssetsGteSupply(uint256 extra) public {
        extra = bound(extra, 0, 100_000e18);
        if (extra > 0) {
            asset.mint(address(vault), extra);
        }
        assertGe(vault.totalAssets(), vault.totalSupply());
    }
}
