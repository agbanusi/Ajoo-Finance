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
    uint256 public defaultThreshold = 30 days; // Time after which a loan can be marked as defaulted
    uint256 public totalDefaultedAmount; // Track total defaulted amount

    struct LoanRequest {
        address borrower;
        uint256 amount;
        uint256 duration;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingDeadline;
        bool executed;
        uint256 amountRepaid;
        bool isDefaulted;
        uint256 lastPaymentTime;
        uint256 defaultedAmount;
    }

    mapping(address => bool) public membershipRequests;
    mapping(address => uint256) public lastContributionTime;
    mapping(uint256 => address) public members;
    mapping(address => uint256) public memberIds;
    mapping(address => uint256) public memberBalance;
    mapping(uint256 => LoanRequest) public loanRequests;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => uint256) public defaultLosses; // Track individual member's share of defaults
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
    event MemberDefaulted(address indexed member, uint256 indexed loanId);
    event DefaultLossCovered(uint256 indexed loanId, address indexed coveredBy, uint256 amount);
    event LoanDefaulted(uint256 indexed loanId, uint256 defaultedAmount);
    event DefaultLossDistributed(uint256 indexed loanId, uint256 lossPerMember);

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

        // admin must be member
        _grantRole(MEMBER_ROLE, _admin);
        members[memberCount] = _admin;
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

        members[memberCount] = _requester;
        memberIds[_requester] = memberCount;
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
            amountRepaid: 0,
            isDefaulted: false,
            lastPaymentTime: block.timestamp,
            defaultedAmount: 0
        });

        emit LoanRequested(loanRequestCount, msg.sender, _amount, _duration);
        loanRequestCount++;
    }

    function vote(uint256 _loanId, bool _inFavor) external onlyRole(MEMBER_ROLE) {
        LoanRequest storage loan = loanRequests[_loanId];
        require(block.timestamp < loan.votingDeadline, "Voting period has ended");
        require(!loan.executed, "Loan has already been executed");
        require(!hasVoted[_loanId][msg.sender], "Already voted");
        hasVoted[_loanId][msg.sender] = true;

        if (_inFavor) {
            loan.votesFor++;
        } else {
            loan.votesAgainst++;
        }

        emit VoteCast(_loanId, msg.sender, _inFavor);
    }

    function executeLoan(uint256 _loanId) external nonReentrant onlyRole(MEMBER_ROLE) {
        LoanRequest storage loan = loanRequests[_loanId];
        uint256 quorum = memberCount / 2; // At least 50% of members must vote
        require(loan.votesFor + loan.votesAgainst >= quorum, "Quorum not reached");
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
        if (_amount > totalDue - loan.amountRepaid) {
            _amount = totalDue - loan.amountRepaid; // Cap the repayment amount
        }

        lendingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 interestPortion = (loan.amount - loan.amountRepaid) * interestRate * (block.timestamp - loan.lastPaymentTime) / (10000 * 365 days); // interest on last principal per second

        // uint256 interestPortion = _amount * interestRate / 10000 ;
        loan.amountRepaid += _amount - interestPortion;
        loan.lastPaymentTime = block.timestamp;

        
        totalInterestEarned += interestPortion;

        emit LoanRepaid(_loanId, msg.sender, _amount);
    }

    function _withdrawInterest() private {
        require(isContributionUpToDate(msg.sender), "Contributions not up to date");
        uint256 interestShare = totalInterestEarned / memberCount;
        // require(interestShare > 0, "No interest to withdraw");

        totalInterestEarned -= interestShare;
        lendingToken.safeTransfer(msg.sender, interestShare);

        emit InterestWithdrawn(msg.sender, interestShare);
    }

    function withdrawInterest() external onlyRole(MEMBER_ROLE) nonReentrant {
        _withdrawInterest();
    }

    function withdrawBalance(uint256 _amount) external onlyRole(MEMBER_ROLE) nonReentrant {
        require(isContributionUpToDate(msg.sender), "Contributions not up to date");
        uint256 actualBalance = memberBalance[msg.sender] - defaultLosses[msg.sender];
        require(_amount > 0 && _amount <= actualBalance, "Invalid withdrawal amount");

        _withdrawInterest();

        memberBalance[msg.sender] -= _amount;
        lendingToken.safeTransfer(msg.sender, _amount);

        if (memberBalance[msg.sender] == 0) {
            _revokeRole(MEMBER_ROLE, msg.sender);
            memberCount--;
            uint256 id = memberIds[msg.sender];
            delete members[id];
            delete memberIds[msg.sender];

            emit MembershipRevoked(msg.sender);
            emit FullWithdrawal(msg.sender, _amount);
        } else {
            emit PartialWithdrawal(msg.sender, _amount);
        }
    }

    // The markLoanAsDefaulted function to allow loss coverage and handle member removal
    function markLoanAsDefaulted(
        uint256 _loanId, 
        bool _coverLoss
    ) external onlyRole(ADMIN_ROLE) nonReentrant {
        LoanRequest storage loan = loanRequests[_loanId];
        require(loan.executed, "Loan not executed");
        require(!loan.isDefaulted, "Loan already defaulted");
        require(
            block.timestamp > loan.lastPaymentTime + defaultThreshold,
            "Loan not yet eligible for default"
        );

        // Calculate remaining unpaid amount
        uint256 totalDue = loan.amount + (loan.amount * interestRate / 10000);
        uint256 remainingUnpaid = totalDue - loan.amountRepaid;
        
        // Mark loan as defaulted
        loan.isDefaulted = true;
        loan.defaultedAmount = remainingUnpaid;

        // Remove defaulted member from the group
        address defaultedMember = loan.borrower;
        if (hasRole(MEMBER_ROLE, defaultedMember)) {
            _revokeRole(MEMBER_ROLE, defaultedMember);
            memberCount--;
            uint256 id = memberIds[defaultedMember];
            delete members[id];
            delete memberIds[defaultedMember];

            emit MemberDefaulted(defaultedMember, _loanId);
            emit MembershipRevoked(defaultedMember);
        }

        if (_coverLoss) {
            // Admin is covering the loss (e.g., after seizing external collateral)
            lendingToken.safeTransferFrom(msg.sender, address(this), remainingUnpaid);
            
            // Update loan status
            loan.amountRepaid = totalDue;
            emit DefaultLossCovered(_loanId, msg.sender, remainingUnpaid);
        } else {
            // Distribute losses to remaining members
            totalDefaultedAmount += remainingUnpaid;
            
            // Recalculate loss per member (excluding the defaulted member)
            uint256 lossPerMember = remainingUnpaid / memberCount;
            
            // Distribute losses to all remaining members
            for (uint256 i = 0; i < memberCount; i++) {
                address member = members[i];
                defaultLosses[member] += lossPerMember;
            }
            
            emit LoanDefaulted(_loanId, remainingUnpaid);
            emit DefaultLossDistributed(_loanId, lossPerMember);
        }
    }

    // The coverDefaultedLoan function to allow loss coverage after loan is already marked defaulted
    function coverDefaultedLoan(uint256 _loanId) external onlyRole(ADMIN_ROLE) nonReentrant {
        LoanRequest storage loan = loanRequests[_loanId];
        require(loan.isDefaulted, "Loan not defaulted");
        require(loan.defaultedAmount > 0, "No remaining default amount");
        require(memberCount > 0, "No members to refund");

        uint256 remainingDefault = loan.defaultedAmount;
        
        // Transfer the coverage amount from the caller
        lendingToken.safeTransferFrom(msg.sender, address(this), remainingDefault);

        // Refund the distributed losses to members
        uint256 refundPerMember = remainingDefault / memberCount;
        for (uint256 i = 0; i < memberCount; i++) {
            address member = members[i];
            if (member != address(0)) {
                defaultLosses[member] -= refundPerMember;
            }
        }

        // Update contract state
        totalDefaultedAmount -= remainingDefault;
        loan.defaultedAmount = 0;
        loan.amountRepaid = loan.amount + (loan.amount * interestRate / 10000);

        emit DefaultLossCovered(_loanId, msg.sender, remainingDefault);
    }

    // Add a view function to check actual available balance
    function getAvailableBalance(address _member) public view returns (uint256) {
        return memberBalance[_member] - defaultLosses[_member];
    }

    function isLoanDefaultEligible(uint256 _loanId) external view returns (bool) {
        LoanRequest storage loan = loanRequests[_loanId];
        return (
            loan.executed &&
            !loan.isDefaulted &&
            block.timestamp > loan.lastPaymentTime + defaultThreshold
        );
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

    function setDefaultThreshold(uint256 _defaultThreshold) external onlyRole(ADMIN_ROLE) {
        defaultThreshold = _defaultThreshold;
    }
}
