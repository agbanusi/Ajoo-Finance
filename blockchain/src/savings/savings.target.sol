// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Import the base Savings contract
import "./savings.base.sol";

contract TargetSavings is Savings {
    mapping(address => uint256) public tokenTargets;

    event TargetSet(address indexed token, uint256 target);
    event TargetReached(address indexed token);

    constructor(
        address _owner,
        address[] memory _acceptedTokens,
        uint256[] memory _targets,
        string memory _name
    ) Savings(_owner, _acceptedTokens, _name) {
        require(_acceptedTokens.length == _targets.length, "Tokens and targets length mismatch");
        for (uint i = 0; i < _acceptedTokens.length; i++) {
            tokenTargets[_acceptedTokens[i]] = _targets[i];
            emit TargetSet(_acceptedTokens[i], _targets[i]);
        }
    }

    function deposit(address _token, uint256 _amount) public override onlyOwner nonReentrant {
        super.deposit(_token, _amount);
        if (tokenSavings[_token] >= tokenTargets[_token]) {
            emit TargetReached(_token);
        }
    }

    function withdraw(address _token, uint256 _amount) public override onlyOwner nonReentrant {
        require(tokenSavings[_token] >= tokenTargets[_token], "Target not reached");
        super.withdraw(_token, _amount);
    }
}

