// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./savings.base.sol";
import "./savings.vault.sol";
import "./savings.target.sol";
import "./savings.challenge.sol";

contract SavingsFactory is Ownable {
    event SavingsCreated(address indexed owner, address savingsContract, address[] acceptedTokens, string savingsType);
    
    mapping(uint=>address) public savings;
    uint public id;
    address[] public acceptableTokens;
    mapping(address => bool) public isTokenAcceptable;

    constructor() Ownable(msg.sender) {}

    function createBaseSavings(address[] calldata _acceptedTokens, string memory _name) external returns (address) {
        require(_acceptedTokens.length > 0 && _acceptedTokens.length <= 32, "Invalid number of tokens");
        validateTokens(_acceptedTokens);

        Savings newSavings = new Savings(msg.sender, _acceptedTokens, _name);
        emit SavingsCreated(msg.sender, address(newSavings), _acceptedTokens, "Base");

        savings[id] = address(newSavings);
        id++;
        return address(newSavings);
    }

    function createVaultSavings(address[] calldata _acceptedTokens, uint256 _lockPeriod, string memory _name) external returns (address) {
        require(_acceptedTokens.length > 0 && _acceptedTokens.length <= 32, "Invalid number of tokens");
        validateTokens(_acceptedTokens);

        VaultSavings newVaultSavings = new VaultSavings(msg.sender, _acceptedTokens, _lockPeriod, _name);
        emit SavingsCreated(msg.sender, address(newVaultSavings), _acceptedTokens, "Vault");

        savings[id] = address(newVaultSavings);
        id++;
        return address(newVaultSavings);
    }

    function createTargetSavings(address[] calldata _acceptedTokens, uint256[] calldata _targets, string memory _name) external returns (address) {
        require(_acceptedTokens.length > 0 && _acceptedTokens.length <= 32, "Invalid number of tokens");
        require(_acceptedTokens.length == _targets.length, "Tokens and targets length mismatch");
        validateTokens(_acceptedTokens);

        TargetSavings newTargetSavings = new TargetSavings(msg.sender, _acceptedTokens, _targets, _name);
        emit SavingsCreated(msg.sender, address(newTargetSavings), _acceptedTokens, "Target");

        savings[id] = address(newTargetSavings);
        id++;
        return address(newTargetSavings);
    }

    function createChallengeSavings(address[] calldata _acceptedTokens, string memory _name) external returns (address) {
        require(_acceptedTokens.length > 0 && _acceptedTokens.length <= 32, "Invalid number of tokens");
        validateTokens(_acceptedTokens);

        SavingsChallenge newChallengeSavings = new SavingsChallenge(msg.sender, _acceptedTokens, _name);
        emit SavingsCreated(msg.sender, address(newChallengeSavings), _acceptedTokens, "Challenge");

        savings[id] = address(newChallengeSavings);
        id++;
        return address(newChallengeSavings);
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