// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626Vault} from "src/ERC4626Vault.sol";
import {ChainlinkOracle} from "src/ChainlinkOracle.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

/// @notice Deploy yield vault + Chainlink oracle adapter (Person 2 — gTurboflex).
contract DeployVaultOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address priceFeed = vm.envOr("CHAINLINK_PRICE_FEED", address(0));
        uint256 staleness = vm.envOr("ORACLE_STALENESS_SECONDS", uint256(3600));

        vm.startBroadcast(deployerPrivateKey);

        MockERC20 underlying = new MockERC20("DeFi Super-App USD", "DSAUSD", 18);
        ERC4626Vault vault = new ERC4626Vault(IERC20(address(underlying)), "DSA Yield Vault", "yvDSA");
        console.log("Underlying asset:", address(underlying));
        console.log("ERC4626 vault:", address(vault));

        if (priceFeed != address(0)) {
            ChainlinkOracle oracle = new ChainlinkOracle(priceFeed, staleness);
            console.log("ChainlinkOracle:", address(oracle));
        } else {
            console.log("CHAINLINK_PRICE_FEED not set - deploy oracle separately on L2");
        }

        vm.stopBroadcast();
    }
}
