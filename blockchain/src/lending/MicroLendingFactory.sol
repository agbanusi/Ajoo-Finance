// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MicroLending.sol";

contract MicroLendingFactory {
    mapping(uint=>address) public lendingCircles;
    uint public id;
    event MicroLendingCreated(address indexed lendingContract, address indexed admin);

    function createMicroLending(
        address _admin,
        address _lendingToken,
        uint256 _contributionAmount,
        uint256 _contributionPeriod,
        uint256 _votingPeriod,
        uint256 _interestRate, string memory _name
    ) external returns (address) {
        MicroLending newLending = new MicroLending(
            _admin,
            _lendingToken,
            _contributionAmount,
            _contributionPeriod,
            _votingPeriod,
            _interestRate,
            _name
        );
        lendingCircles[id] = address(newLending);
        id++;

        emit MicroLendingCreated(address(newLending), _admin);
        return address(newLending);
    }
}