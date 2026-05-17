// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626Vault} from "src/ERC4626Vault.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract VaultHandler is Test {
    ERC4626Vault public vault;
    MockERC20 public asset;

    constructor(ERC4626Vault vault_, MockERC20 asset_) {
        vault = vault_;
        asset = asset_;
        asset.mint(address(this), 10_000_000e18);
        asset.approve(address(vault), type(uint256).max);
        vault.deposit(1000, address(this));
    }

    function deposit(uint256 assets) external {
        assets = bound(assets, 1, 100_000e18);
        vault.deposit(assets, address(this));
    }

    function withdraw(uint256 assets) external {
        assets = bound(assets, 1, vault.maxWithdraw(address(this)));
        if (assets == 0) return;
        vault.withdraw(assets, address(this), address(this));
    }
}

contract VaultInvariantTest is StdInvariant, Test {
    ERC4626Vault internal vault;
    MockERC20 internal asset;
    VaultHandler internal handler;

    function setUp() public {
        asset = new MockERC20("AST", "AST", 18);
        vault = new ERC4626Vault(IERC20(address(asset)), "vAST", "vAST");
        handler = new VaultHandler(vault, asset);
        targetContract(address(handler));
    }

    function invariant_TotalAssetsMatchesBalance() public view {
        assertEq(vault.totalAssets(), asset.balanceOf(address(vault)));
    }

    function invariant_SharesLteAssets() public view {
        assertGe(vault.totalAssets(), vault.totalSupply());
    }
}
