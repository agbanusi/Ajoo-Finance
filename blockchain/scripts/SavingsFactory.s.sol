// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/savings/savingsFactory.sol";
import "../src/savings/savingsFactory2.sol";
import "../src/savings/ExtendedSavingsFactory.sol";
import "../src/savings/CrossChainSavingsFactory.sol";


contract DeploySavingsFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address vrfCoordinator = vm.envAddress("VRF_COORDINATOR");
        uint64 subscriptionId = uint64(vm.envUint("SUBSCRIPTION_ID"));
        uint64 factoryType = uint64(vm.envUint("SAVINGS_FACTORY_TYPE"));
        // bytes32 keyHash = vm.envBytes32("KEY_HASH");

        vm.startBroadcast(deployerPrivateKey);
        if(factoryType == 0){
        SavingsFactory factory = new SavingsFactory();

        console.log("SavingsFactory deployed at:", address(factory));
        }else if(factoryType == 1){
            SavingsFactory2 factory = new SavingsFactory2();

        console.log("SavingsFactory2 deployed at:", address(factory));
        }else if(factoryType == 2){
            ExtendedSavingsFactory factory = new ExtendedSavingsFactory(
            vrfCoordinator,
            subscriptionId,
            keccak256("keyHash:test")
        );

        console.log("ExtendedSavingsFactory deployed at:", address(factory));
        }else if(factoryType == 3){
            CrossChainSavingsFactory factory = new CrossChainSavingsFactory();

        console.log("CrossChainSavingsFactory deployed at:", address(factory));
        }

        vm.stopBroadcast();
    }
}