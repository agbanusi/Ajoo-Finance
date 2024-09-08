// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../savings/savings.custodial.sol";
import "./IKintoID.sol";

contract CustodialSavingsKYC is CustodialSavings {
    IKintoID public immutable kintoID;

    modifier onlyKYC() {
        require(kintoID.isKYC(msg.sender), "KYC required");
        _;
    }

    constructor(
        address _creator,
        address _recipient,
        address[] memory _acceptedTokens,
        uint256 _unlockTime,
        address _kintoIDAddress
    ) CustodialSavings(_creator, _recipient, _acceptedTokens, _unlockTime) {
        require(_kintoIDAddress != address(0), "Invalid KintoID address");
        kintoID = IKintoID(_kintoIDAddress);
    }

    function withdraw(address _token) public override onlyKYC {
        super.withdraw(_token);
    }

    // Override to prevent owner from withdrawing
    function withdraw(address _token, uint256 _amount) public override {
        revert("Withdrawal not allowed");
    }
}