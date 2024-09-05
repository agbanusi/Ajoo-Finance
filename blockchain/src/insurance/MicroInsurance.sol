// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MicroInsurance is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");

    IERC20 public immutable paymentToken;
    uint256 public monthlyPremium;
    uint256 public votingPeriod;
    uint256 public claimVotingThreshold; // Percentage of total members needed to pass a claim (in basis points)
    uint256 public maxClaimAmount;

    struct Member {
        bool isActive;
        uint256 lastPaymentTimestamp;
        uint256 totalPremiumsPaid;
    }

    struct Claim {
        address claimant;
        uint256 amount;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingDeadline;
        bool executed;
        bool vetoed;
    }

    mapping(address => Member) public members;
    mapping(uint256 => Claim) public claims;
    uint256 public claimCount;
    uint256 public totalMembers;
    uint256 public poolBalance;

    event MembershipRequested(address indexed requester);
    event MembershipApproved(address indexed member);
    event MembershipRejected(address indexed requester);
    event PremiumPaid(address indexed member, uint256 amount);
    event ClaimSubmitted(uint256 indexed claimId, address indexed claimant, uint256 amount);
    event ClaimVoteCast(uint256 indexed claimId, address indexed voter, bool inFavor);
    event ClaimPaid(uint256 indexed claimId, address indexed claimant, uint256 amount);
    event ClaimRejected(uint256 indexed claimId);
    event ClaimVetoed(uint256 indexed claimId);

    constructor(
        address _admin,
        address _paymentToken,
        uint256 _monthlyPremium,
        uint256 _votingPeriod,
        uint256 _claimVotingThreshold,
        uint256 _maxClaimAmount
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
        paymentToken = IERC20(_paymentToken);
        monthlyPremium = _monthlyPremium;
        votingPeriod = _votingPeriod;
        claimVotingThreshold = _claimVotingThreshold;
        maxClaimAmount = _maxClaimAmount;
    }

    function requestMembership() external {
        require(!members[msg.sender].isActive, "Already a member");
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _requester) external onlyRole(ADMIN_ROLE) {
        require(!members[_requester].isActive, "Already a member");
        members[_requester].isActive = true;
        totalMembers++;
        emit MembershipApproved(_requester);
    }

    function rejectMembership(address _requester) external onlyRole(ADMIN_ROLE) {
        emit MembershipRejected(_requester);
    }

    function payPremium() external nonReentrant {
        require(members[msg.sender].isActive, "Not a member");
        require(block.timestamp >= members[msg.sender].lastPaymentTimestamp + 30 days, "Premium already paid this month");

        paymentToken.safeTransferFrom(msg.sender, address(this), monthlyPremium);
        members[msg.sender].lastPaymentTimestamp = block.timestamp;
        members[msg.sender].totalPremiumsPaid += monthlyPremium;
        poolBalance += monthlyPremium;

        emit PremiumPaid(msg.sender, monthlyPremium);
    }

    function submitClaim(uint256 _amount) external nonReentrant onlyRole(MEMBER_ROLE){
        require(members[msg.sender].isActive, "Not a member");
        require(_amount <= maxClaimAmount, "Claim amount exceeds maximum");
        require(isPremiumUpToDate(msg.sender), "Premium not up to date");

        claims[claimCount] = Claim({
            claimant: msg.sender,
            amount: _amount,
            votesFor: 0,
            votesAgainst: 0,
            votingDeadline: block.timestamp + votingPeriod,
            executed: false,
            vetoed: false
        });

        emit ClaimSubmitted(claimCount, msg.sender, _amount);
        claimCount++;
    }

    function voteOnClaim(uint256 _claimId, bool _inFavor) external onlyRole(MEMBER_ROLE){
        require(members[msg.sender].isActive, "Not a member");
        require(isPremiumUpToDate(msg.sender), "Premium not up to date");
        Claim storage claim = claims[_claimId];
        require(block.timestamp < claim.votingDeadline, "Voting period has ended");
        require(!claim.executed && !claim.vetoed, "Claim already processed");

        if (_inFavor) {
            claim.votesFor++;
        } else {
            claim.votesAgainst++;
        }

        emit ClaimVoteCast(_claimId, msg.sender, _inFavor);
    }

    function executeClaim(uint256 _claimId) external nonReentrant onlyRole(MEMBER_ROLE){
       _executeClaim(_claimId);
    }

    function _executeClaim(uint256 _claimId) internal nonReentrant {
        Claim storage claim = claims[_claimId];
        require(block.timestamp >= claim.votingDeadline, "Voting period has not ended");
        require(!claim.executed && !claim.vetoed, "Claim already processed");

        uint256 totalVotes = claim.votesFor + claim.votesAgainst;
        uint256 approvalThreshold = (totalMembers * claimVotingThreshold) / 10000;

        if ((claim.votesFor > claim.votesAgainst && totalVotes >= approvalThreshold) || claim.vetoed) {
            require(poolBalance >= claim.amount, "Insufficient pool balance");
            poolBalance -= claim.amount;
            paymentToken.safeTransfer(claim.claimant, claim.amount);
            claim.executed = true;
            emit ClaimPaid(_claimId, claim.claimant, claim.amount);
        } else {
            claim.executed = true;
            emit ClaimRejected(_claimId);
        }
    }

    function vetoClaim(uint256 _claimId) external onlyRole(ADMIN_ROLE) {
        Claim storage claim = claims[_claimId];
        require(!claim.executed && !claim.vetoed, "Claim already processed");
        require(claim.votesFor <= claim.votesAgainst, "Cannot veto approved claim");

        claim.vetoed = true;
        _executeClaim(_claimId);
        emit ClaimVetoed(_claimId);
    }

    function isPremiumUpToDate(address _member) public view returns (bool) {
        return block.timestamp <= members[_member].lastPaymentTimestamp + 30 days;
    }

    // Admin functions to update parameters
    function setMonthlyPremium(uint256 _newPremium) external onlyRole(ADMIN_ROLE) {
        monthlyPremium = _newPremium;
    }

    function setVotingPeriod(uint256 _newPeriod) external onlyRole(ADMIN_ROLE) {
        votingPeriod = _newPeriod;
    }

    function setClaimVotingThreshold(uint256 _newThreshold) external onlyRole(ADMIN_ROLE) {
        require(_newThreshold <= 10000, "Threshold cannot exceed 100%");
        claimVotingThreshold = _newThreshold;
    }

    function setMaxClaimAmount(uint256 _newMaxAmount) external onlyRole(ADMIN_ROLE) {
        maxClaimAmount = _newMaxAmount;
    }
}