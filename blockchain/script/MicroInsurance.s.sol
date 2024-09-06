// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/insurance/MicroInsuranceFactory.sol";

contract CreateMicroInsurance is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        address paymentToken = vm.envAddress("PAYMENT_TOKEN");
        uint256 monthlyPremium = vm.envUint("MONTHLY_PREMIUM");
        uint256 votingPeriod = vm.envUint("VOTING_PERIOD");
        uint256 claimVotingThreshold = vm.envUint("CLAIM_VOTING_THRESHOLD");
        uint256 maxClaimAmount = vm.envUint("MAX_CLAIM_AMOUNT");

        MicroInsuranceFactory factory = MicroInsuranceFactory(factoryAddress);

        vm.startBroadcast(deployerPrivateKey);

        address microInsuranceAddress = factory.createMicroInsurance(
            paymentToken,
            monthlyPremium,
            votingPeriod,
            claimVotingThreshold,
            maxClaimAmount
        );

        console.log("MicroInsurance contract created at:", microInsuranceAddress);

        vm.stopBroadcast();
    }
}