// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Import the base Savings contract
import "./savings.base.sol";

contract InvestmentSavings is Savings {
    IERC4626 public yieldStrategyManager;
    uint256 public investmentPercentage;
    address public investmentToken;
    uint256 public BASE = 10000;

    event InvestmentPercentageSet(uint256 percentage);
    event Invested(address indexed token, uint256 amount);
    event Divested(address indexed token, uint256 amount);

    constructor(
        address _owner,
        address[] memory _acceptedTokens,
        address _yieldStrategyManager,
        uint256 _investmentPercentage,
        string memory _name
    ) Savings(_owner, _acceptedTokens, _name) {
        require(_investmentPercentage <= BASE, "Invalid investment percentage");
        yieldStrategyManager = IERC4626(_yieldStrategyManager);
        investmentToken = yieldStrategyManager.asset(); //usually usdt/usdc/weth
        require(investmentToken == _acceptedTokens[0], "StrategyManager asset must be among accepted tokens and be the first in array");
        investmentPercentage = _investmentPercentage;
        emit InvestmentPercentageSet(_investmentPercentage);
    }

    function deposit(address _token, uint256 _amount) public override onlyOwner nonReentrant {
        super.deposit(_token, _amount);
        uint256 investAmount = (_amount * investmentPercentage) / BASE;
        if (investAmount > 0 && isInvestmentToken(_token)) {
            IERC20(_token).approve(address(yieldStrategyManager), investAmount);
            yieldStrategyManager.deposit(investAmount, address(this));
            emit Invested(_token, investAmount);
        }
    }

    function withdraw(address _token, uint256 _amount) public override onlyOwner nonReentrant {
        uint256 contractBalance = IERC20(_token).balanceOf(address(this));
        if (contractBalance < _amount && isInvestmentToken(_token)) {
            uint256 shortfall = _amount - contractBalance;
            uint256 shares = yieldStrategyManager.convertToShares(shortfall);
            yieldStrategyManager.redeem(shares, address(this), address(this));
            emit Divested(_token, shortfall);
        } else if (contractBalance < _amount) {
            revert("Insufficient balance");
        }
        super.withdraw(_token, _amount);
    }

    function getTotalBalance(address _token) public view returns (uint256) {
        uint256 contractBalance = IERC20(_token).balanceOf(address(this));
        if(isInvestmentToken(_token)){
          uint256 investedBalance = yieldStrategyManager.convertToAssets(yieldStrategyManager.balanceOf(address(this)));
          return contractBalance + investedBalance;
        }else{
           return contractBalance;
        }
    }

    function isInvestmentToken(address _token)public view returns (bool){
      return _token == investmentToken;
    }
}