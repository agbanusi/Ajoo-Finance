// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./savings.circle.sol";
import "./savings.group.sol";




contract ExtendedSavingsFactory is Ownable {
    event SavingsCreated(address indexed owner, address savingsContract, address[] acceptedTokens, string savingsType);

    mapping(uint=>address) public savings;
    uint public id;
    address[] public acceptableTokens;
    mapping(address => bool) public isTokenAcceptable;
    address COORDINATOR;
    uint64 subscriptionId;
    bytes32 keyHash;
    

    constructor( address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash) Ownable(msg.sender) {
          COORDINATOR = _vrfCoordinator;
          subscriptionId = _subscriptionId;
          keyHash = _keyHash;
        }

    function createCircleSavings(address _acceptedToken, address _recipient, uint256 _periodDuration, string memory _name) external returns (address) {
        address[] memory tokens = new address[](1);
        tokens[0] = _acceptedToken;
        //default 2.5%
        CircleSavings newCustodialSavings = new CircleSavings(_acceptedToken, msg.sender, owner(),_periodDuration, 250, COORDINATOR, subscriptionId, keyHash, _name);
        emit SavingsCreated(msg.sender, address(newCustodialSavings), tokens, "Circle");

        savings[id] = address(newCustodialSavings);
        id++;
        return address(newCustodialSavings);
    }

    function createGroupSavings(
        address[] calldata _acceptedTokens, string memory _name
    ) public returns (address) {
        require(_acceptedTokens.length > 0 && _acceptedTokens.length <= 32, "Invalid number of tokens");
        validateTokens(_acceptedTokens);

        GroupSavings newGroupSavings = new GroupSavings(
            msg.sender,
            _acceptedTokens,
            msg.sender,
            _name
        );
        emit SavingsCreated(msg.sender, address(newGroupSavings), _acceptedTokens, "Group");

        savings[id] = address(newGroupSavings);
        id++;
        return address(newGroupSavings);
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