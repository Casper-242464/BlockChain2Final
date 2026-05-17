// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {AMMFactory} from "src/AMMFactory.sol";

contract DeployAMM is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        AMMFactory factoryImpl = new AMMFactory();
        console.log("AMMFactory Implementation deployed at:", address(factoryImpl));

        console.log("Implementation is locked.");
        console.log("Deploy a UUPS-compatible proxy and call initialize(owner) through the proxy.");

        vm.stopBroadcast();
    }
}
