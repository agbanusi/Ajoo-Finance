// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Import the base Savings contract
import "./savings.base.sol";

contract VaultSavings is Savings {
    uint256 public lockPeriod;
    uint256 public startTime;
    mapping(address => uint256) public lastWithdrawalTime;

    event LockPeriodSet(uint256 period);
    event WithdrawalTimeReset(address indexed token);

    constructor(
        address _owner,
        address[] memory _acceptedTokens,
        uint256 _lockPeriod,
        string memory _name
    ) Savings(_owner, _acceptedTokens, _name) {
        lockPeriod = _lockPeriod;
        startTime = block.timestamp;
        emit LockPeriodSet(_lockPeriod);
    }

    function withdraw(address _token, uint256 _amount) public override onlyOwner nonReentrant {
        if(lastWithdrawalTime[_token] == 0){
          lastWithdrawalTime[_token] = startTime;
        }
        require(block.timestamp >= lastWithdrawalTime[_token] + lockPeriod, "Lock period not ended");
        super.withdraw(_token, _amount);
        // it is assumed any amount left is to be reinvested
        lastWithdrawalTime[_token] = block.timestamp;
        emit WithdrawalTimeReset(_token);
    }
}
