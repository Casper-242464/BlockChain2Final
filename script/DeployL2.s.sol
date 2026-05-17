// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {AMMFactory} from "src/AMMFactory.sol";

contract DeployL2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy AMMFactory implementation
        AMMFactory factoryImpl = new AMMFactory();
        console.log("AMMFactory Implementation deployed at:", address(factoryImpl));

        console.log("Implementation is locked.");
        console.log("Deploy a UUPS-compatible proxy and call initialize(owner) through the proxy.");

        // Example: Create a pair (requires token addresses)
        // address tokenA = 0x...; // Replace with actual token addresses
        // address tokenB = 0x...;
        // address pair = factoryImpl.createPair(tokenA, tokenB);
        // console.log("Pair created at:", pair);

        vm.stopBroadcast();
    }
}
