// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./savings.cross.sol";
import "../crossChain/ChainLinkCross.sol";




contract CrossChainSavingsFactory is Ownable {
    event SavingsCreated(address indexed owner, address savingsContract, address[] acceptedTokens, string savingsType);
    event CrossChainManagerCreated(address indexed owner, address managerContract, address ccipRouter);
    
    address[] public acceptableTokens;
    mapping(address => bool) public isTokenAcceptable;
    

    constructor() Ownable(msg.sender) {}

    function createCrossChainCircleSavings(address[] calldata _acceptedTokens, address _protocolCrossChainManager, string memory _name) external returns (address) {
        CrossChainSavings newCustodialSavings = new CrossChainSavings(msg.sender, _acceptedTokens, _protocolCrossChainManager, _name);
        emit SavingsCreated(msg.sender, address(newCustodialSavings), _acceptedTokens, "Circle");
        return address(newCustodialSavings);
    }

    function createCrossChainConsumer(
        address _ccipRouter
    ) public returns (address) {
        ProtocolCrossChainManager newCrossChainManager = new ProtocolCrossChainManager(
            owner(),
            _ccipRouter
        );
        
        emit CrossChainManagerCreated(owner(), address(newCrossChainManager), _ccipRouter);
        return address(newCrossChainManager);
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