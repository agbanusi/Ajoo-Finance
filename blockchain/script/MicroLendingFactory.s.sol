// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/lending/MicroLendingFactory.sol";

contract DeployMicroLendingFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        MicroLendingFactory factory = new MicroLendingFactory();

        console.log("MicroLendingFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}