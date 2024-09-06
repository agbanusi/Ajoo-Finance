// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/savings/savingsFactory.sol";

contract DeploySavingsFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address vrfCoordinator = vm.envAddress("VRF_COORDINATOR");
        uint64 subscriptionId = uint64(vm.envUint("SUBSCRIPTION_ID"));
        bytes32 keyHash = vm.envBytes32("KEY_HASH");

        vm.startBroadcast(deployerPrivateKey);

        SavingsFactory factory = new SavingsFactory(
            vrfCoordinator,
            subscriptionId,
            keyHash
        );

        console.log("SavingsFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}