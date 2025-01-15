// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "./savings.base.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


// contract CustodialSavings is Savings {
//     using SafeERC20 for IERC20;

//     address public immutable creator;
//     address public recipient;
//     uint256 public immutable unlockTime;
//     bool public recipientChanged;

//     event RecipientChanged(address indexed oldRecipient, address indexed newRecipient);
//     event FundsWithdrawn(address indexed recipient, address indexed token, uint256 amount);

//     constructor(
//         address _creator,
//         address _recipient,
//         address[] memory _acceptedTokens,
//         uint256 _unlockTime,
//         string memory _name
//     ) Savings(_creator, _acceptedTokens, _name) {
//         require(_creator != _recipient, "Creator cannot be recipient");
//         require(_unlockTime > block.timestamp, "unlock time is in the past");
//         creator = _creator;
//         recipient = _recipient;
//         unlockTime = _unlockTime;
//         recipientChanged = false;
//     }

//     function setRecipient(address _newRecipient) external onlyOwner {
//         require(!recipientChanged, "Recipient can only be changed once");
//         require(_newRecipient != address(0), "Invalid recipient address");
//         require(_newRecipient != owner() && _newRecipient != creator, "Invalid recipient");
        
//         address oldRecipient = recipient;
//         recipient = _newRecipient;
//         recipientChanged = true;
        
//         emit RecipientChanged(oldRecipient, _newRecipient);
//     }

//     function deposit(address _token, uint256 _amount) public override {
//         require(isTokenAccepted[_token], "Token not accepted");
//         require(_amount > 0, "Amount must be greater than 0");
        
//         IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
//         tokenSavings[_token] += _amount;
        
//         emit Deposit(msg.sender, _token, _amount);
//     }

//     function withdraw(address _token) public virtual {
//         require(msg.sender == recipient, "Only recipient can withdraw");
//         require(block.timestamp >= unlockTime, "Funds are still locked");
//         require(isTokenAccepted[_token], "Token not accepted");
        
//         uint256 amount = tokenSavings[_token];
//         require(amount > 0, "No funds to withdraw");
        
//         tokenSavings[_token] = 0;
//         IERC20(_token).safeTransfer(recipient, amount);
        
//         emit FundsWithdrawn(recipient, _token, amount);
        
//         // Check if this was the last token with a balance
//         // bool allTokensWithdrawn = true;
//         // for (uint i = 0; i < acceptedTokens.length; i++) {
//         //     if (tokenSavings[acceptedTokens[i]] > 0) {
//         //         allTokensWithdrawn = false;
//         //         break;
//         //     }
//         // }
        
//         // If all tokens have been withdrawn, self-destruct the contract
//         // if (allTokensWithdrawn) {
//         //     selfdestruct(payable(recipient));
//         // }
//     }

//     // Override to prevent owner from withdrawing
//     function withdraw(address _token, uint256 _amount) public virtual override {
//         revert("Withdrawal not allowed");
//     }
// }