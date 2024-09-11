// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../savings/savings.circle.sol";
import "./IKintoID.sol";

contract CircleSavingsKYC is CircleSavings {
    IKintoID public immutable kintoID;

    modifier onlyKYC() {
        require(kintoID.isKYC(msg.sender) && kintoID.isSanctionsSafe(msg.sender) && kintoID.isCompany(msg.sender), "KYC required");
        _;
    }

    constructor(
        address _token,
        address _admin,
        address _taxCollector,
        uint256 _periodDuration,
        uint256 _protocolTaxRate,
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        address _kintoIDAddress, string memory _name
    ) CircleSavings(
        _token,
        _admin,
        _taxCollector,
        _periodDuration,
        _protocolTaxRate,
        _vrfCoordinator,
        _subscriptionId,
        _keyHash,
        _name
    ) {
        require(_kintoIDAddress != address(0), "Invalid KintoID address");
        kintoID = IKintoID(_kintoIDAddress);
    }

    // Override the withdraw function to include KYC check
    function withdraw() public override nonReentrant onlyKYC {
        super.withdraw();
    }

}