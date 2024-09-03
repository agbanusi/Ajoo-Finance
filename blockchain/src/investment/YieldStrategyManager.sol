// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "./strategies/AaveYieldStrategy.sol";
import "./strategies/MorphoYieldStrategy.sol";
import "./strategies/UniswapYieldStrategy.sol";

contract YieldStrategyManager is ERC4626, Ownable, ReentrancyGuard {
    AaveYieldStrategy public aaveStrategy;
    MorphoYieldStrategy public morphoStrategy;
    UniswapYieldStrategy public uniswapStrategy;

    uint256 public aaveAllocation;
    uint256 public morphoAllocation;
    uint256 public uniswapAllocation;
    uint256 public totalAssetsLocked;

    event YieldHarvested(uint256 amount);
    event AllocationsUpdated(uint256 aave, uint256 morpho, uint256 uniswap);
    event StrategiesUpdated(address aave, address morpho, address uniswap);

    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _aaveStrategy,
        address _morphoStrategy,
        address _uniswapStrategy,
        uint256 _aaveAllocation,
        uint256 _morphoAllocation,
        uint256 _uniswapAllocation,
        address owner
    ) ERC4626(_asset) ERC20(_name, _symbol) Ownable(owner) {
        aaveStrategy = AaveYieldStrategy(_aaveStrategy);
        morphoStrategy = MorphoYieldStrategy(_morphoStrategy);
        uniswapStrategy = UniswapYieldStrategy(_uniswapStrategy);
        transferOwnership(owner);

        // Default allocations
        aaveAllocation = _aaveAllocation; //2000;
        morphoAllocation = _morphoAllocation; //3000;
        uniswapAllocation = _uniswapAllocation; //5000;
    }

    function setAllocations(uint256 _aave, uint256 _morpho, uint256 _uniswap) external onlyOwner {
        require(_aave + _morpho + _uniswap == 10000, "Allocations must sum to 100%");
        aaveAllocation = _aave;
        morphoAllocation = _morpho;
        uniswapAllocation = _uniswap;
        emit AllocationsUpdated(_aave, _morpho, _uniswap);
    }

    function updateStrategies(address _aaveStrategy, address _morphoStrategy, address _uniswapStrategy) external onlyOwner {
        aaveStrategy = AaveYieldStrategy(_aaveStrategy);
        morphoStrategy = MorphoYieldStrategy(_morphoStrategy);
        uniswapStrategy = UniswapYieldStrategy(_uniswapStrategy);
        emit StrategiesUpdated(_aaveStrategy, _morphoStrategy, _uniswapStrategy);
    }

    function totalAssets() public view override returns (uint256) {
        return totalAssetsLocked;
    }

    function totalStrategyAssets() public view returns (uint256) {
        return aaveStrategy.getTotalValue() + morphoStrategy.getTotalValue() + uniswapStrategy.getTotalValue();
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);

        uint256 aaveAmount = (assets * aaveAllocation) / 10000;
        uint256 morphoAmount = (assets * morphoAllocation) / 10000;
        uint256 uniswapAmount = assets - aaveAmount - morphoAmount;
        totalAssetsLocked += assets;

        if(aaveAmount > 0){
            IERC20(asset()).approve(address(aaveStrategy), aaveAmount);
            aaveStrategy.deposit(aaveAmount);
        }

        if(morphoAmount > 0){
            IERC20(asset()).approve(address(morphoStrategy), morphoAmount);
            morphoStrategy.deposit(morphoAmount);
        }

        if(uniswapAmount > 0){
            IERC20(asset()).approve(address(uniswapStrategy), uniswapAmount);
            uniswapStrategy.deposit(uniswapAmount);
        }
        
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal override {
        super._withdraw(caller, receiver, owner, assets, shares);

        uint256 aaveAmount = (assets * aaveAllocation) / 10000;
        uint256 morphoAmount = (assets * morphoAllocation) / 10000;
        uint256 uniswapAmount = assets - aaveAmount - morphoAmount;
        totalAssetsLocked += assets;

        if(aaveAmount > 0){
            aaveStrategy.withdraw(aaveAmount);
        }

        if(morphoAmount > 0){
            morphoStrategy.withdraw(morphoAmount);
        }

        if(uniswapAmount > 0){
            uniswapStrategy.withdraw(uniswapAmount);
        }
    }

    function harvestYields() external nonReentrant {
        uint256 beforeBalance = IERC20(asset()).balanceOf(address(this));

        aaveStrategy.harvestYield();
        morphoStrategy.harvestYield();
        uniswapStrategy.harvestYield();

        uint256 yieldAmount = IERC20(asset()).balanceOf(address(this)) - beforeBalance;
        if(yieldAmount <= 0){
            return;
        }
        totalAssetsLocked += yieldAmount;
        emit YieldHarvested(yieldAmount);

        // Reinvest the yield
        uint256 aaveAmount = (yieldAmount * aaveAllocation) / 10000;
        uint256 morphoAmount = (yieldAmount * morphoAllocation) / 10000;
        uint256 uniswapAmount = yieldAmount - aaveAmount - morphoAmount;

        if(aaveAmount > 0){
            IERC20(asset()).approve(address(aaveStrategy), aaveAmount);
            aaveStrategy.deposit(aaveAmount);
        }

        if(morphoAmount > 0){
            IERC20(asset()).approve(address(morphoStrategy), morphoAmount);
            morphoStrategy.deposit(morphoAmount);
        }

        if(uniswapAmount > 0){
            IERC20(asset()).approve(address(uniswapStrategy), uniswapAmount);
            uniswapStrategy.deposit(uniswapAmount);
        }
    }
}