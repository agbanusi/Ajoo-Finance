// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts-ccip/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts-ccip/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";



contract CircleSavings is ReentrancyGuard, Ownable, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;

    struct Member {
        bool isActive;
        bool isFrozen;
        uint256 lastContributionPeriod;
        uint256 lastWithdrawn;
    }

    IERC20 public token;
    uint256 public periodDuration;
    uint256 public contributionAmount;
    uint256 public startTime;
    uint256 public currentPeriod;
    uint256 public cycleLength;
    address[] public memberList;
    mapping(address => Member) public members;
    mapping(address => bool) public selected;
    uint256 public totalContributed;
    uint256 public constant MIN_PERIOD_DURATION = 1 days;
    uint256 public protocolTaxRate; // in basis points (e.g., 100 = 1%)
    address public taxCollector;
    
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint256 public randomResult;
    address public selectedWithdrawer;
    bool public withdrawerSelected;

    event MemberAdded(address member);
    event MemberRemoved(address member);
    event MemberFrozen(address member);
    event MemberUnfrozen(address member);
    event ContributionMade(address member, uint256 amount, uint256 period);
    event PayoutMade(address member, uint256 amount, uint256 period);
    event CycleStarted(uint256 startTime, uint256 cycleLength, uint256 contributionAmount);
    event PeriodEnded(uint256 period);
    event TokenUpdated(address newToken);
    event PeriodDurationUpdated(uint256 newDuration);
    event ProtocolTaxRateUpdated(uint256 newRate);
    event WithdrawerSelected(address withdrawer);

    constructor(
        address _token,
        address _admin,
        address _taxCollector,
        uint256 _periodDuration,
        uint256 _protocolTaxRate,
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) Ownable(_admin) VRFConsumerBaseV2(_vrfCoordinator) {
        require(_periodDuration >= MIN_PERIOD_DURATION, "Period duration too short");
        require(_protocolTaxRate <= 1000, "Tax rate too high"); // Max 10%
        token = IERC20(_token);
        periodDuration = _periodDuration;
        protocolTaxRate = _protocolTaxRate;
        taxCollector = _taxCollector;

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    function addMember(address _member) external onlyOwner {
        require(!members[_member].isActive, "Member already exists");
        require(startTime == 0 || currentPeriod == 0, "Cannot add member during active cycle");
        memberList.push(_member);
        members[_member] = Member(true, false, 0, 0);
        cycleLength = memberList.length;
        emit MemberAdded(_member);
    }

    function removeMember(address _member) external onlyOwner {
        require(members[_member].isActive, "Member does not exist");
        require(startTime == 0 || currentPeriod == 0, "Cannot remove member during active cycle");
        
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        delete members[_member];
        cycleLength = memberList.length;
        emit MemberRemoved(_member);
    }

    function startCycle(uint256 _contributionAmount) external onlyOwner {
        require(startTime == 0, "Cycle already started");
        require(memberList.length > 1, "Need at least two members");
        require(_contributionAmount > 0, "Contribution amount must be greater than 0");
        startTime = block.timestamp;
        currentPeriod = 1;
        cycleLength = memberList.length;
        contributionAmount = _contributionAmount;
        emit CycleStarted(startTime, cycleLength, contributionAmount);
    }

    function contribute() external nonReentrant {
        _contribute(msg.sender);
    }

    function triggerAutoSave(address _member) external onlyOwner nonReentrant {
        _contribute(_member);
    }

    function _contribute(address _member) internal {
        require(startTime > 0, "Cycle not started");
        require(members[_member].isActive, "Not a member");
        require(!members[_member].isFrozen, "Member is frozen");
        require(currentPeriod <= cycleLength, "Cycle completed");
        require(members[_member].lastContributionPeriod < currentPeriod, "Already contributed this period");

        token.safeTransferFrom(_member, address(this), contributionAmount);
        members[_member].lastContributionPeriod = members[_member].lastContributionPeriod + 1;
        totalContributed += contributionAmount;

        // Unfreeze member if they were frozen
        if (members[_member].isFrozen && members[_member].lastContributionPeriod == currentPeriod) {
            members[_member].isFrozen = false;
            emit MemberUnfrozen(_member);
        }

        emit ContributionMade(_member, contributionAmount, currentPeriod);

        if (totalContributed == contributionAmount * cycleLength) {
            _endPeriod(true);
        }
    }

    function withdraw() public virtual nonReentrant {
        require(startTime > 0, "Cycle not started");
        require(currentPeriod <= cycleLength, "Cycle completed");
        require(totalContributed == contributionAmount * cycleLength, "Not all contributions received");
        require(withdrawerSelected, "Withdrawer not selected yet");
        require(msg.sender == selectedWithdrawer, "Not your turn to withdraw");
        require(!members[msg.sender].isFrozen, "Member is frozen");
        require(members[msg.sender].lastWithdrawn < startTime, "Already withdrawn this cycle");

        address payoutMember = selectedWithdrawer; //_getEligibleWithdrawer();
        require(payoutMember == msg.sender, "Not your turn to withdraw");
        require(!members[payoutMember].isFrozen, "Member is frozen");

        uint256 amount = contributionAmount * cycleLength;
        uint256 protocolTax = (amount * protocolTaxRate) / 10000;
        uint256 payout = amount - protocolTax;
        members[msg.sender].lastWithdrawn = block.timestamp;
        withdrawerSelected = false;
        selectedWithdrawer = address(0);

        token.safeTransfer(payoutMember, payout);
        token.safeTransfer(taxCollector, protocolTax);

        emit PayoutMade(payoutMember, payout, currentPeriod);

        _endPeriod(false);
    }

    function _endPeriod(bool trigger) internal {
        emit PeriodEnded(currentPeriod);
        totalContributed = 0;
        currentPeriod++;

        if (currentPeriod > cycleLength) {
            startTime = 0; // Reset for next cycle

        } else {
            // Check and freeze members who didn't contribute
            for (uint i = 0; i < memberList.length; i++) {
                address member = memberList[i];
                if (members[member].lastContributionPeriod < currentPeriod - 1) {
                    members[member].isFrozen = true;
                    emit MemberFrozen(member);
                }
            }

            if(trigger)requestRandomNumber();
        }
    }

    function _getEligibleWithdrawer() internal view returns (address) {
        for (uint i = currentPeriod - 1; i < memberList.length; i++) {
            if (!members[memberList[i]].isFrozen) {
                return memberList[i];
            }
        }
        for (uint i = 0; i < currentPeriod - 1; i++) {
            if (!members[memberList[i]].isFrozen) {
                return memberList[i];
            }
        }
        revert("No eligible withdrawer found");
    }

    function selectWithdrawer() internal {
        uint256 index = randomResult % memberList.length;
        for (uint i = 0; i < memberList.length; i++) {
            uint256 actualIndex = (index + i) % memberList.length;
            address potentialWithdrawer = memberList[actualIndex];
            if (!members[potentialWithdrawer].isFrozen &&
                members[potentialWithdrawer].lastWithdrawn < startTime) {
                selectedWithdrawer = potentialWithdrawer;
                withdrawerSelected = true;
                emit WithdrawerSelected(selectedWithdrawer);
                return;
            }
        }
        // If we've gone through all members and none are eligible, request a new random number
        requestRandomNumber();
    }

    function requestRandomNumber() internal {
        COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
        randomResult = randomWords[0];
        selectWithdrawer();
    }

    function setToken(address _newToken) external onlyOwner {
        require(_newToken != address(0), "Invalid token address");
        token = IERC20(_newToken);
        emit TokenUpdated(_newToken);
    }

    function setPeriodDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration >= MIN_PERIOD_DURATION, "Period duration too short");
        require(startTime == 0, "Cannot change duration during active cycle");
        periodDuration = _newDuration;
        emit PeriodDurationUpdated(_newDuration);
    }

    // function setProtocolTaxRate(uint256 _newRate) external onlyOwner {
    //     require(_newRate <= 1000, "Tax rate too high"); // Max 10%
    //     protocolTaxRate = _newRate;
    //     emit ProtocolTaxRateUpdated(_newRate);
    // }

    function getCurrentPeriod() public view returns (uint256) {
        if (startTime == 0) return 0;
        uint256 elapsedPeriods = (block.timestamp - startTime) / periodDuration;
        return elapsedPeriods < cycleLength ? elapsedPeriods + 1 : 0;
    }

    function getMemberCount() public view returns (uint256) {
        return memberList.length;
    }

    function getEligibleWithdrawer() public view returns (address) {
        if (currentPeriod == 0 || currentPeriod > cycleLength) return address(0);
        return selectedWithdrawer; //_getEligibleWithdrawer();
    }

    function updateVRFSubscription(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    // Function to update VRF callback gas limit
    function updateCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }
}