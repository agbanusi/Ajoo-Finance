// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/lending/MicroLendingFactory.sol";

contract CreateMicroLending is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address lendingToken = vm.envAddress("LENDING_TOKEN");
        uint256 contributionAmount = vm.envUint("CONTRIBUTION_AMOUNT");
        uint256 contributionPeriod = vm.envUint("CONTRIBUTION_PERIOD");
        uint256 votingPeriod = vm.envUint("VOTING_PERIOD");
        uint256 interestRate = vm.envUint("INTEREST_RATE");

        MicroLendingFactory factory = MicroLendingFactory(factoryAddress);

        vm.startBroadcast(deployerPrivateKey);

        address microLendingAddress = factory.createMicroLending(
            admin,
            lendingToken,
            contributionAmount,
            contributionPeriod,
            votingPeriod,
            interestRate
        );

        console.log("MicroLending contract created at:", microLendingAddress);

        vm.stopBroadcast();
    }
}