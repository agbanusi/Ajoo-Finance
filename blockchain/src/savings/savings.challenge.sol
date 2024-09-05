// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./savings.base.sol";

contract SavingsChallenge is Savings {
    struct Challenge {
        uint256 target;
        uint256 deadline;
        bool completed;
    }

    mapping(address => Challenge) public challenges;

    event ChallengeCreated(address indexed token, uint256 target, uint256 deadline);
    event ChallengeCompleted(address indexed token);

    constructor(address _user, address[] memory _acceptedTokens)
        Savings(_user, _acceptedTokens)
    {
        _transferOwnership(_user);
    }

    function createChallenge(address _token, uint256 _target, uint256 _durationInDays) external onlyOwner {
        require(isTokenAccepted[_token], "Token not accepted");
        require(_target > 0, "Target must be greater than 0");
        require(_durationInDays > 0, "Duration must be greater than 0");

        uint256 deadline = block.timestamp + (_durationInDays * 1 days);
        challenges[_token] = Challenge({
            target: _target,
            deadline: deadline,
            completed: false
        });

        emit ChallengeCreated(_token, _target, deadline);
    }

    function deposit(address _token, uint256 _amount) public override onlyOwner nonReentrant {
        super.deposit(_token, _amount);
        checkChallengeCompletion(_token);
    }

    function autoSave(uint256 _amount) public override onlyOperator nonReentrant {
        super.autoSave(_amount);
        checkChallengeCompletion(defaultToken);
    }

    function checkChallengeCompletion(address _token) internal {
        Challenge storage challenge = challenges[_token];
        if (!challenge.completed && 
            tokenSavings[_token] >= challenge.target && 
            block.timestamp <= challenge.deadline) {
            challenge.completed = true;
            emit ChallengeCompleted(_token);
        }
    }

    function withdraw(address _token, uint256 _amount) public override onlyOwner nonReentrant {
        Challenge storage challenge = challenges[_token];
        require(challenge.completed || block.timestamp > challenge.deadline || challenge.target == 0, 
                "Challenge not completed and deadline not reached");
        super.withdraw(_token, _amount);
    }

    function getChallengeStatus(address _token) external view returns (uint256, uint256, bool) {
        Challenge storage challenge = challenges[_token];
        return (challenge.target, challenge.deadline, challenge.completed);
    }
}