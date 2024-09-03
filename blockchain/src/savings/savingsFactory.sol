// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./savings.base.sol";

contract SavingsFactory is Ownable {
    event SavingsCreated(address indexed owner, address savingsContract, address[] acceptedTokens);
    
    address[] public acceptableTokens;
    mapping(address => bool) public isTokenAcceptable;

    constructor()Ownable(msg.sender){}

    function createBaseSavings(address[] calldata _acceptedTokens) external returns (address) {
        require(_acceptedTokens.length > 0 && _acceptedTokens.length <= 32, "Invalid number of tokens");
        
        for (uint i = 0; i < _acceptedTokens.length; i++) {
            require(isTokenAcceptable[_acceptedTokens[i]], "Token not acceptable");
        }

        Savings newSavings = new Savings(msg.sender, _acceptedTokens);
        emit SavingsCreated(msg.sender, address(newSavings), _acceptedTokens);
        return address(newSavings);
    }

    function updateAcceptableToken(address[] calldata _acceptedTokens) external onlyOwner {
        require(_acceptedTokens.length > 0 && _acceptedTokens.length <= 32, "Invalid number of tokens");
        
        for (uint i = 0; i < _acceptedTokens.length; i++) {
          address token = _acceptedTokens[i];
          acceptableTokens.push(token);
          isTokenAcceptable[token] = true;
        }
       
    }

    function getAcceptableTokens() external view returns (address[] memory) {
        return acceptableTokens;
    }
}