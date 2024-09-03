// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IMorphoLendingPool {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function convertToShares(uint256 assets) external view returns (uint256 shares);
    function balanceOf(address user) external view returns (uint256 shares);
}

contract MorphoYieldStrategy is ReentrancyGuard, AccessControl {
    IERC20 public immutable usdtToken;
    IMorphoLendingPool public immutable metaMorphoVault;

    uint256 private totalSharesDeposited;

    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant USER_ROLE_ADMIN = keccak256("USER_ROLE_ADMIN");

    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, uint256 amount, uint256 shares);
    event YieldHarvested(address indexed user, uint256 amount);

    constructor(address _usdtToken, address _metaMorphoVault, address owner, address proxy) {
        usdtToken = IERC20(_usdtToken);
        metaMorphoVault = IMorphoLendingPool(_metaMorphoVault);

        _setRoleAdmin(USER_ROLE, USER_ROLE_ADMIN);
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(USER_ROLE, owner);
        _grantRole(USER_ROLE, msg.sender);
        _grantRole(USER_ROLE_ADMIN, proxy);
       
    }

    function deposit(uint256 amount) external onlyRole(USER_ROLE) nonReentrant {
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        usdtToken.approve(address(metaMorphoVault), amount);
        uint256 sharesBefore = metaMorphoVault.balanceOf(address(this));
        metaMorphoVault.deposit(amount, address(this));
        uint256 sharesAfter = metaMorphoVault.balanceOf(address(this));
        uint256 sharesReceived = sharesAfter - sharesBefore;
        totalSharesDeposited += sharesReceived;
        emit Deposited(msg.sender, amount, sharesReceived);
    }

    function withdraw(uint256 amount) external onlyRole(USER_ROLE) nonReentrant {
        uint256 sharesToWithdraw = metaMorphoVault.convertToShares(amount);
        require(sharesToWithdraw <= totalSharesDeposited, "Cannot withdraw more than deposited");
        uint256 sharesBefore = metaMorphoVault.balanceOf(address(this));
        metaMorphoVault.withdraw(amount, msg.sender, address(this));
        uint256 sharesAfter = metaMorphoVault.balanceOf(address(this));
        uint256 sharesWithdrawn = sharesBefore - sharesAfter;
        totalSharesDeposited -= sharesWithdrawn;
        emit Withdrawn(msg.sender, amount, sharesWithdrawn);
    }

    function harvestYield() external onlyRole(USER_ROLE) nonReentrant {
        uint256 totalShares = metaMorphoVault.balanceOf(address(this));
        require(totalShares > totalSharesDeposited, "No yield to harvest");
        
        uint256 yieldShares = totalShares - totalSharesDeposited;
        uint256 yieldAmount = metaMorphoVault.convertToAssets(yieldShares);
        
        metaMorphoVault.withdraw(yieldAmount, msg.sender, address(this));
        
        emit YieldHarvested(msg.sender, yieldAmount);
    }

    function getTotalValue() public view returns (uint256) {
        return metaMorphoVault.convertToAssets(metaMorphoVault.balanceOf(address(this)));
    }

    function getYieldAmount() public view returns (uint256) {
        uint256 totalShares = metaMorphoVault.balanceOf(address(this));
        if (totalShares <= totalSharesDeposited) return 0;
        uint256 yieldShares = totalShares - totalSharesDeposited;
        return metaMorphoVault.convertToAssets(yieldShares);
    }
}


