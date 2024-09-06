// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/insurance/MicroInsuranceFactory.sol";

contract DeployMicroInsuranceFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        MicroInsuranceFactory factory = new MicroInsuranceFactory();

        console.log("MicroInsuranceFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}