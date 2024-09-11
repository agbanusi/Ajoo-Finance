// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MicroLending is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");

    IERC20 public immutable lendingToken;
    uint256 public contributionAmount;
    uint256 public contributionPeriod;
    uint256 public votingPeriod;
    uint256 public interestRate; // In basis points (1% = 100)

    uint256 public totalInterestEarned;
    uint256 public memberCount;
    string public name;

    struct LoanRequest {
        address borrower;
        uint256 amount;
        uint256 duration;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingDeadline;
        bool executed;
        uint256 amountRepaid;
    }

    mapping(address => bool) public membershipRequests;
    mapping(address => uint256) public lastContributionTime;
    mapping(address => uint256) public memberBalance;
    mapping(uint256 => LoanRequest) public loanRequests;
    uint256 public loanRequestCount;

    event MembershipRequested(address indexed requester);
    event MembershipApproved(address indexed member);
    event MembershipRejected(address indexed requester);
    event ContributionMade(address indexed member, uint256 amount);
    event LoanRequested(uint256 indexed loanId, address indexed borrower, uint256 amount, uint256 duration);
    event VoteCast(uint256 indexed loanId, address indexed voter, bool inFavor);
    event LoanExecuted(uint256 indexed loanId, address indexed borrower, uint256 amount);
    event LoanRepaid(uint256 indexed loanId, address indexed borrower, uint256 amount);
    event InterestWithdrawn(address indexed member, uint256 amount);
    event PartialWithdrawal(address indexed member, uint256 amount);
    event FullWithdrawal(address indexed member, uint256 amount);
    event MembershipRevoked(address indexed member);

    constructor(
        address _admin,
        address _lendingToken,
        uint256 _contributionAmount,
        uint256 _contributionPeriod,
        uint256 _votingPeriod,
        uint256 _interestRate,
        string memory _name
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
        lendingToken = IERC20(_lendingToken);
        contributionAmount = _contributionAmount;
        contributionPeriod = _contributionPeriod;
        votingPeriod = _votingPeriod;
        interestRate = _interestRate;
        name = _name;
    }

    function requestMembership() external {
        require(!hasRole(MEMBER_ROLE, msg.sender), "Already a member");
        require(!membershipRequests[msg.sender], "Request already pending");
        membershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _requester) external onlyRole(ADMIN_ROLE) {
        require(membershipRequests[_requester], "No pending request");
        delete membershipRequests[_requester];
        _grantRole(MEMBER_ROLE, _requester);
        memberCount++;
        emit MembershipApproved(_requester);
    }

    function rejectMembership(address _requester) external onlyRole(ADMIN_ROLE) {
        require(membershipRequests[_requester], "No pending request");
        delete membershipRequests[_requester];
        emit MembershipRejected(_requester);
    }

    function contribute() external onlyRole(MEMBER_ROLE) nonReentrant {
        require(block.timestamp >= lastContributionTime[msg.sender] + contributionPeriod, "Too early to contribute");
        lendingToken.safeTransferFrom(msg.sender, address(this), contributionAmount);
        lastContributionTime[msg.sender] = block.timestamp;
        memberBalance[msg.sender] += contributionAmount;
        emit ContributionMade(msg.sender, contributionAmount);
    }

    function requestLoan(uint256 _amount, uint256 _duration) external onlyRole(MEMBER_ROLE) {
        require(_amount > 0, "Loan amount must be greater than 0");
        require(_duration > 0, "Loan duration must be greater than 0");

        loanRequests[loanRequestCount] = LoanRequest({
            borrower: msg.sender,
            amount: _amount,
            duration: _duration,
            votesFor: 0,
            votesAgainst: 0,
            votingDeadline: block.timestamp + votingPeriod,
            executed: false,
            amountRepaid: 0
        });

        emit LoanRequested(loanRequestCount, msg.sender, _amount, _duration);
        loanRequestCount++;
    }

    function vote(uint256 _loanId, bool _inFavor) external onlyRole(MEMBER_ROLE) {
        LoanRequest storage loan = loanRequests[_loanId];
        require(block.timestamp < loan.votingDeadline, "Voting period has ended");
        require(!loan.executed, "Loan has already been executed");

        if (_inFavor) {
            loan.votesFor++;
        } else {
            loan.votesAgainst++;
        }

        emit VoteCast(_loanId, msg.sender, _inFavor);
    }

    function executeLoan(uint256 _loanId) external nonReentrant onlyRole(MEMBER_ROLE) {
        LoanRequest storage loan = loanRequests[_loanId];
        require(block.timestamp >= loan.votingDeadline, "Voting period has not ended");
        require(!loan.executed, "Loan has already been executed");
        require(loan.votesFor > loan.votesAgainst, "Loan was not approved");

        loan.executed = true;
        lendingToken.safeTransfer(loan.borrower, loan.amount);

        emit LoanExecuted(_loanId, loan.borrower, loan.amount);
    }

    function repayLoan(uint256 _loanId, uint256 _amount) external nonReentrant onlyRole(MEMBER_ROLE) {
        LoanRequest storage loan = loanRequests[_loanId];
        require(loan.executed, "Loan is not active");
        require(msg.sender == loan.borrower, "Only borrower can repay");

        uint256 totalDue = loan.amount + (loan.amount * interestRate / 10000);
        require(loan.amountRepaid + _amount <= totalDue, "Repayment amount too high");

        lendingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 interestPortion = _amount * interestRate / 10000 ;
        loan.amountRepaid += _amount - interestPortion;

        
        totalInterestEarned += interestPortion;

        emit LoanRepaid(_loanId, msg.sender, _amount - interestPortion);
    }

    function withdrawInterest() public onlyRole(MEMBER_ROLE) nonReentrant {
        require(isContributionUpToDate(msg.sender), "Contributions not up to date");
        uint256 interestShare = totalInterestEarned / memberCount;
        // require(interestShare > 0, "No interest to withdraw");

        totalInterestEarned -= interestShare;
        memberCount--;  // Temporarily decrease to avoid double-dipping
        lendingToken.safeTransfer(msg.sender, interestShare);
        memberCount++;  // Restore member count

        emit InterestWithdrawn(msg.sender, interestShare);
    }

    function withdrawBalance(uint256 _amount) external onlyRole(MEMBER_ROLE) nonReentrant {
        require(isContributionUpToDate(msg.sender), "Contributions not up to date");
        require(_amount > 0 && _amount <= memberBalance[msg.sender], "Invalid withdrawal amount");
        withdrawInterest();

        memberBalance[msg.sender] -= _amount;
        lendingToken.safeTransfer(msg.sender, _amount);

        if (memberBalance[msg.sender] == 0) {
            _revokeRole(MEMBER_ROLE, msg.sender);
            memberCount--;
            emit MembershipRevoked(msg.sender);
            emit FullWithdrawal(msg.sender, _amount);
        } else {
            emit PartialWithdrawal(msg.sender, _amount);
        }
    }

    function isContributionUpToDate(address _member) public view returns (bool) {
        return block.timestamp <= lastContributionTime[_member] + contributionPeriod;
    }

    // Admin functions to update parameters
    function setContributionAmount(uint256 _newAmount) external onlyRole(ADMIN_ROLE) {
        contributionAmount = _newAmount;
    }

    function setContributionPeriod(uint256 _newPeriod) external onlyRole(ADMIN_ROLE) {
        contributionPeriod = _newPeriod;
    }

    function setVotingPeriod(uint256 _newPeriod) external onlyRole(ADMIN_ROLE) {
        votingPeriod = _newPeriod;
    }

    function setInterestRate(uint256 _newRate) external onlyRole(ADMIN_ROLE) {
        interestRate = _newRate;
    }
}