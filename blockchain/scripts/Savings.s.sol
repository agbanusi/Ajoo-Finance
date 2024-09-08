// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/savings/savingsFactory.sol";
import "../src/savings/savingsFactory2.sol";
import "../src/savings/ExtendedSavingsFactory.sol";
import "../src/savings/CrossChainSavingsFactory.sol";


contract CreateSavings is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        address factoryAddress2 = vm.envAddress("FACTORY_ADDRESS2");
        address factoryAddress3 = vm.envAddress("FACTORY_ADDRESS3");
        address factoryAddress4 = vm.envAddress("FACTORY_ADDRESS4");
        uint8 savingsType = uint8(vm.envUint("SAVINGS_TYPE"));
        uint256 percent = vm.envUint("INVESTMENT_PERCENTAGE");
        address strmgr = vm.envAddress("STRATEGY_MANAGER");
        address[] memory acceptedTokens = vm.envAddress("ACCEPTED_TOKENS", ",");

        SavingsFactory factory = SavingsFactory(factoryAddress);
        SavingsFactory2 factory2 = SavingsFactory2(factoryAddress2);
        ExtendedSavingsFactory factory3 = ExtendedSavingsFactory(factoryAddress3);
        CrossChainSavingsFactory factory4 = CrossChainSavingsFactory(factoryAddress4);

        vm.startBroadcast(deployerPrivateKey);

        address savingsAddress;
        string memory savingsName;

        // factory.updateAcceptableTokens(acceptedTokens);
        // factory2.updateAcceptableTokens(acceptedTokens);
        // factory3.updateAcceptableTokens(acceptedTokens);
        // factory4.updateAcceptableTokens(acceptedTokens);

        if (savingsType == 1) {
            savingsName = "Base Savings";
            savingsAddress = factory.createBaseSavings(acceptedTokens);
        } else if (savingsType == 2) {
            savingsName = "Custodial Savings";
            address recipient = vm.envAddress("RECIPIENT");
            uint256 unlockPeriod = vm.envUint("UNLOCK_PERIOD");
            savingsAddress = factory2.createCustodialSavings(acceptedTokens, recipient, unlockPeriod);
        } else if (savingsType == 3) {
            savingsName = "Vault Savings";
            uint256 lockPeriod = vm.envUint("LOCK_PERIOD");
            savingsAddress = factory.createVaultSavings(acceptedTokens, lockPeriod);
        } else if (savingsType == 4) {
            savingsName = "Circle Savings";
            address acceptedToken = acceptedTokens[0];
            address recipient = vm.envAddress("RECIPIENT");
            uint256 periodDuration = vm.envUint("PERIOD_DURATION");
            savingsAddress = factory3.createCircleSavings(acceptedToken, recipient, periodDuration);
        } else if (savingsType == 5) {
            savingsName = "Group Savings";
            savingsAddress = factory3.createGroupSavings(acceptedTokens);
        } else if (savingsType == 6) {
            savingsName = "Challenge Savings";
            savingsAddress = factory.createChallengeSavings(acceptedTokens);
        } else if (savingsType == 7) {
            savingsName = "Investment Savings";
            savingsAddress = factory2.createInvestmentSavings(acceptedTokens, percent, strmgr);
        } else if (savingsType == 8) {
            address manager = vm.envAddress("CROSS_CHAIN_MANAGER");
            savingsName = "CrossChain Savings";
            savingsAddress = factory4.createCrossChainCircleSavings(acceptedTokens, manager);
        } else {
            revert("Invalid savings type");
        }

        console.log("%s created at: %s", savingsName, savingsAddress);

        vm.stopBroadcast();
    }
}