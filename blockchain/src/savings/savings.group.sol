// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./savings.base.sol";

contract GroupSavings is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct WithdrawalRequest {
        address recipient;
        uint256 amount;
        bool approved;
    }

    struct AutoSendSettings {
        bool enabled;
        uint256 amount;
        uint256 period;
        uint256 lastSendTime;
    }

    address public defaultToken;
    address public operator;
    mapping(address => uint256) public tokenSavings;
    address[] public acceptedTokens;
    mapping(address => bool) public isTokenAccepted;
    mapping(address => bool) public isMember;
    address[] public members;
    mapping(address => WithdrawalRequest[]) public withdrawalRequests;
    AutoSendSettings public autoSendSettings;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event WithdrawalRequested(address indexed requester, uint256 amount, uint256 requestId);
    event WithdrawalApproved(address indexed requester, uint256 amount, uint256 requestId);
    event OperatorUpdated(address indexed newOperator);
    event AutoSendSettingsUpdated(bool enabled, uint256 amount, uint256 period);
    event AutoSendExecuted(uint256 totalAmount, uint256 membersCount);

    constructor(address _owner, address[] memory _acceptedTokens, address _initialMember) Ownable(_owner) {
        for (uint i = 0; i < _acceptedTokens.length; i++) {
            addAcceptedToken(_acceptedTokens[i]);
        }
        _addMember(_initialMember);
        defaultToken = _acceptedTokens[0];
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a group member");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Not the operator");
        _;
    }

    function setOperator(address _newOperator) external onlyOwner {
        operator = _newOperator;
        emit OperatorUpdated(_newOperator);
    }

    function setAutoSendSettings(bool _enabled, uint256 _amount, uint256 _period) external onlyOwner {
        autoSendSettings.enabled = _enabled;
        autoSendSettings.amount = _amount;
        autoSendSettings.period = _period;
        autoSendSettings.lastSendTime = block.timestamp;
        emit AutoSendSettingsUpdated(_enabled, _amount, _period);
    }

    function addMember(address _member) public onlyOwner {
        _addMember(_member);
    }

    function _addMember(address _member) internal {
        require(!isMember[_member], "Already a member");
        // isSavingsAccount(_member);
        isMember[_member] = true;
        members.push(_member);
        emit MemberAdded(_member);
    }

    function removeMember(address _member) public onlyOwner {
        require(isMember[_member], "Not a member");
        isMember[_member] = false;
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        emit MemberRemoved(_member);
    }

    function deposit(address _token, uint256 _amount) public onlyMember nonReentrant {
        require(isTokenAccepted[_token], "Token not accepted");
        require(_amount > 0, "Amount must be greater than 0");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        tokenSavings[_token] += _amount;
        emit Deposit(msg.sender, _token, _amount);
    }

    function requestWithdrawal(address _token, uint256 _amount) public onlyMember {
        require(isTokenAccepted[_token], "Token not accepted");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 requestId = withdrawalRequests[_token].length;
        withdrawalRequests[_token].push(WithdrawalRequest({
            recipient: msg.sender,
            amount: _amount,
            approved: false
        }));
        emit WithdrawalRequested(msg.sender, _amount, requestId);
    }

    function approveWithdrawal(address _token, uint256 _requestId) public onlyOwner {
        require(_requestId < withdrawalRequests[_token].length, "Invalid request ID");
        WithdrawalRequest storage request = withdrawalRequests[_token][_requestId];
        require(!request.approved, "Already approved");
        require(tokenSavings[_token] >= request.amount, "Insufficient balance");
        // isSavingsAccount(request.recipient);

        request.approved = true;
        tokenSavings[_token] -= request.amount;
        IERC20(_token).safeTransfer(request.recipient, request.amount);
        emit WithdrawalApproved(request.recipient, request.amount, _requestId);
    }

    function batchSend(address _token, address[] memory _recipients, uint256[] memory _amounts) public onlyOwner nonReentrant {
        require(_recipients.length == _amounts.length, "Arrays length mismatch");
        require(isTokenAccepted[_token], "Token not accepted");

        uint256 totalAmount = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        require(tokenSavings[_token] >= totalAmount, "Insufficient balance");

        for (uint i = 0; i < _recipients.length; i++) {
            require(isMember[_recipients[i]], "Recipient not a member");
            isSavingsAccount(_recipients[i]);
            IERC20(_token).safeTransfer(_recipients[i], _amounts[i]);
            emit Withdraw(_recipients[i], _token, _amounts[i]);
        }
        tokenSavings[_token] -= totalAmount;
    }

    function autoSendToAll() public onlyOperator nonReentrant {
        require(autoSendSettings.enabled, "Auto-send is not enabled");
        require(block.timestamp >= autoSendSettings.lastSendTime + autoSendSettings.period, "Auto-send period not elapsed");

        uint256 totalAmount = autoSendSettings.amount * members.length;
        require(tokenSavings[defaultToken] >= totalAmount, "Insufficient balance");

        for (uint i = 0; i < members.length; i++) {
            isSavingsAccount(members[i]);
            IERC20(defaultToken).safeTransfer(members[i], autoSendSettings.amount);
            emit Withdraw(members[i], defaultToken, autoSendSettings.amount);
        }
        tokenSavings[defaultToken] -= totalAmount;
        autoSendSettings.lastSendTime = block.timestamp;

        emit AutoSendExecuted(totalAmount, members.length);
    }

    function addAcceptedToken(address _token) internal {
        require(!isTokenAccepted[_token], "Token already accepted");
        require(acceptedTokens.length < 32, "Maximum token limit reached");
        acceptedTokens.push(_token);
        isTokenAccepted[_token] = true;
    }

    function isSavingsAccount(address _user) public view {
        require(Savings(_user).savingsCompatible(), "Not a compatible savings account");
    }

    function getAcceptedTokens() external view returns (address[] memory) {
        return acceptedTokens;
    }

    function getMembers() external view returns (address[] memory) {
        return members;
    }

    function getBalance(address _token) external view returns (uint256) {
        return tokenSavings[_token];
    }
}