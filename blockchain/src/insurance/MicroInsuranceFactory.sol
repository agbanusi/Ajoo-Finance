// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MicroInsurance.sol";

contract MicroInsuranceFactory {
    mapping(uint=>address) public insuranceCircles;
    uint public id;
    event MicroInsuranceCreated(address indexed lendingContract, address indexed admin);

    function createMicroInsurance(
        address _paymentToken,
        uint256 _monthlyPremium,
        uint256 _votingPeriod,
        uint256 _claimVotingThreshold,
        uint256 _maxClaimAmount, string memory _name
    ) external returns (address) {
        MicroInsurance newLending = new MicroInsurance(
            msg.sender,
            _paymentToken,
            _monthlyPremium,
            _votingPeriod,
            _claimVotingThreshold,
            _maxClaimAmount,
            _name
        );
        insuranceCircles[id] = address(newLending);
        id++;

        emit MicroInsuranceCreated(address(newLending), msg.sender);
        return address(newLending);
    }
}