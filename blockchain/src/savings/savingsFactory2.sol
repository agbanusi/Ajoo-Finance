// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./savings.circle.sol";
import "./savings.group.sol";
import "./savings.custodial.sol";
import "./savings.investment.sol";




contract SavingsFactory2 is Ownable {
    event SavingsCreated(address indexed owner, address savingsContract, address[] acceptedTokens, string savingsType);
    
    address[] public acceptableTokens;
    mapping(address => bool) public isTokenAcceptable;

    constructor() Ownable(msg.sender) {}

    function createCustodialSavings(address[] calldata _acceptedTokens, address _recipient, uint256 _unlockPeriod) external returns (address) {
        require(_acceptedTokens.length > 0 && _acceptedTokens.length <= 32, "Invalid number of tokens");
        validateTokens(_acceptedTokens);

        CustodialSavings newCustodialSavings = new CustodialSavings(msg.sender, _recipient, _acceptedTokens, block.timestamp + _unlockPeriod);
        emit SavingsCreated(msg.sender, address(newCustodialSavings), _acceptedTokens, "Custodial");
        return address(newCustodialSavings);
    }

     function createInvestmentSavings(address[] calldata _acceptedTokens, uint256 _investmentPercentage, address _yieldStrategyManager) external returns (address) {
        require(_acceptedTokens.length > 0 && _acceptedTokens.length <= 32, "Invalid number of tokens");
        require(_yieldStrategyManager != address(0), "Yield strategy manager not set");
        validateTokens(_acceptedTokens);

        InvestmentSavings newInvestmentSavings = new InvestmentSavings(msg.sender, _acceptedTokens, _yieldStrategyManager, _investmentPercentage);
        emit SavingsCreated(msg.sender, address(newInvestmentSavings), _acceptedTokens, "Investment");
        return address(newInvestmentSavings);
    }

    function updateAcceptableTokens(address[] calldata _acceptedTokens) external onlyOwner {
        require(_acceptedTokens.length > 0 && _acceptedTokens.length <= 32, "Invalid number of tokens");
        
        for (uint i = 0; i < _acceptedTokens.length; i++) {
            address token = _acceptedTokens[i];
            if (!isTokenAcceptable[token]) {
                acceptableTokens.push(token);
                isTokenAcceptable[token] = true;
            }
        }
    }
    
    function getAcceptableTokens() external view returns (address[] memory) {
        return acceptableTokens;
    }

    function validateTokens(address[] calldata _tokens) internal view {
        for (uint i = 0; i < _tokens.length; i++) {
            require(isTokenAcceptable[_tokens[i]], "Token not acceptable");
        }
    }
}