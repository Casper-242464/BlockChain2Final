// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../src/AMMFactory.sol";
import "../src/AMMPair.sol";

contract DeployAMM is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy AMMFactory implementation
        AMMFactory factoryImpl = new AMMFactory();
        console.log("AMMFactory Implementation deployed at:", address(factoryImpl));

        // For L2 deployment, we deploy the implementation directly
        // In production, you would deploy a proxy pointing to this implementation
        // For Base Sepolia, ensure the RPC is set in foundry.toml or via --rpc-url

        // Initialize the factory (since it's upgradeable, but deployed directly)
        factoryImpl.initialize(msg.sender);
        console.log("AMMFactory initialized with owner:", msg.sender);

        // Example: Create a pair (requires token addresses)
        // address tokenA = 0x...; // Replace with actual token addresses
        // address tokenB = 0x...;
        // address pair = factoryImpl.createPair(tokenA, tokenB);
        // console.log("Pair created at:", pair);

        vm.stopBroadcast();
    }
}
