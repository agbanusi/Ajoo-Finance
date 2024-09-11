// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Savings is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bool public autoSaveEnabled;
    address public operator;
    address public defaultToken;
    string public name;


    mapping(address => uint256) public tokenSavings;
    address[] public acceptedTokens;
    mapping(address => bool) public isTokenAccepted;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event AutoSaveToggled(bool enabled, address defaultToken, address operator);

    constructor(address _owner, address[] memory _acceptedTokens, string memory _name)Ownable(_owner) {
        name = _name;
        for (uint i = 0; i < _acceptedTokens.length; i++) {
            addAcceptedToken(_acceptedTokens[i]);
        }
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Not authorized");
        _;
    }

    function toggleAutoSave(bool _enabled, address _defaultToken, address _operator) external onlyOwner {
        require(isTokenAccepted[_defaultToken], "Token not accepted");
        autoSaveEnabled = _enabled;
        defaultToken = _defaultToken;
        operator = _operator;
        emit AutoSaveToggled(_enabled, _defaultToken, _operator);
    }

    function deposit(address _token, uint256 _amount) public virtual onlyOwner nonReentrant {
        require(isTokenAccepted[_token], "Token not accepted");
        require(_amount > 0, "Amount must be greater than 0");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        tokenSavings[_token] += _amount;
        emit Deposit(msg.sender, _token, _amount);
    }
    

    function withdraw(address _token, uint256 _amount) public virtual onlyOwner nonReentrant {
        require(isTokenAccepted[_token], "Token not accepted");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 balance = IERC20(_token).balanceOf(address(this));

        if(balance > tokenSavings[_token]){
            balance = tokenSavings[_token];
        }
        require(_amount <= tokenSavings[_token], "Insufficient balance");
        tokenSavings[_token] -= _amount;
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _token, _amount);
    }

    function autoSave(uint256 _amount) public virtual onlyOperator nonReentrant {
        require(autoSaveEnabled, "Auto-save is not enabled");
        require(_amount > 0, "Amount must be greater than 0");
        IERC20(defaultToken).safeTransferFrom(owner(), address(this), _amount);
        tokenSavings[defaultToken] += _amount;
        emit Deposit(owner(), defaultToken, _amount);
    }

    function getBalance(address _token) external view returns (uint256) {
        return tokenSavings[_token];
    }

    function addAcceptedToken(address _token) internal {
        require(!isTokenAccepted[_token], "Token already accepted");
        require(acceptedTokens.length < 32, "Maximum token limit reached");
        acceptedTokens.push(_token);
        isTokenAccepted[_token] = true;
    }

    function getAcceptedTokens() external view returns (address[] memory) {
        return acceptedTokens;
    }

    function savingsCompatible() external pure returns (bool){
        return true;
    }
}

// no rebase
// save in strong currencies
// save in RWA assets