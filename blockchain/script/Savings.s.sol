// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/savings/savingsFactory.sol";

contract CreateSavings is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        uint8 savingsType = uint8(vm.envUint("SAVINGS_TYPE"));
        address[] memory acceptedTokens = vm.envAddress("ACCEPTED_TOKENS", ",");

        SavingsFactory factory = SavingsFactory(factoryAddress);

        vm.startBroadcast(deployerPrivateKey);

        address savingsAddress;
        string memory savingsName;

        if (savingsType == 1) {
            savingsName = "Base Savings";
            savingsAddress = factory.createBaseSavings(acceptedTokens);
        } else if (savingsType == 2) {
            savingsName = "Custodial Savings";
            address recipient = vm.envAddress("RECIPIENT");
            uint256 unlockPeriod = vm.envUint("UNLOCK_PERIOD");
            savingsAddress = factory.createCustodialSavings(acceptedTokens, recipient, unlockPeriod);
        } else if (savingsType == 3) {
            savingsName = "Vault Savings";
            uint256 lockPeriod = vm.envUint("LOCK_PERIOD");
            savingsAddress = factory.createVaultSavings(acceptedTokens, lockPeriod);
        } else if (savingsType == 4) {
            savingsName = "Circle Savings";
            address acceptedToken = acceptedTokens[0];
            address recipient = vm.envAddress("RECIPIENT");
            uint256 periodDuration = vm.envUint("PERIOD_DURATION");
            savingsAddress = factory.createCircleSavings(acceptedToken, recipient, periodDuration);
        } else if (savingsType == 5) {
            savingsName = "Group Savings";
            address[] memory initialMembers = vm.envAddress("INITIAL_MEMBERS", ",");
            savingsAddress = factory.createGroupSavings(acceptedTokens, initialMembers);
        } else if (savingsType == 6) {
            savingsName = "Challenge Savings";
            savingsAddress = factory.createChallengeSavings(acceptedTokens);
        } else {
            revert("Invalid savings type");
        }

        console.log("%s created at: %s", savingsName, savingsAddress);

        vm.stopBroadcast();
    }
}