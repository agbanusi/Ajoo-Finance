// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IAToken is IERC20 {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

interface IPool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

contract AaveYieldStrategy is ReentrancyGuard, AccessControl {
    IPool public immutable pool;
    IAToken public immutable aToken;
    IERC20 public immutable underlyingAsset;

    uint256 private totalDeposited;

    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant USER_ROLE_ADMIN = keccak256("USER_ROLE_ADMIN");

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event YieldHarvested(address indexed user, uint256 amount);

    constructor(address _pool, address _aToken, address owner) {
        pool = IPool(_pool);
        aToken = IAToken(_aToken);
        underlyingAsset = IERC20(aToken.UNDERLYING_ASSET_ADDRESS());
        
        _setRoleAdmin(USER_ROLE, USER_ROLE_ADMIN);
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(USER_ROLE, owner);
        _grantRole(USER_ROLE, msg.sender);
        _grantRole(USER_ROLE_ADMIN, owner);
    }

    function deposit(uint256 amount) external onlyRole(USER_ROLE) nonReentrant {
        require(underlyingAsset.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        underlyingAsset.approve(address(pool), amount);
        pool.supply(address(underlyingAsset), amount, address(this), 0);
        totalDeposited += amount;
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyRole(USER_ROLE) nonReentrant {
        require(amount <= totalDeposited, "Cannot withdraw more than deposited");
        uint256 withdrawn = pool.withdraw(address(underlyingAsset), amount, msg.sender);
        totalDeposited -= withdrawn;
        emit Withdrawn(msg.sender, withdrawn);
    }

    function harvestYield() external onlyRole(USER_ROLE) nonReentrant {
        uint256 aTokenBalance = aToken.balanceOf(address(this));
        require(aTokenBalance > totalDeposited, "No yield to harvest");
        
        uint256 yieldAmount = aTokenBalance - totalDeposited;
        uint256 withdrawn = pool.withdraw(address(underlyingAsset), yieldAmount, msg.sender);
        
        emit YieldHarvested(msg.sender, withdrawn);
    }

    function getTotalValue() public view returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    function getYieldAmount() public view returns (uint256) {
        uint256 aTokenBalance = aToken.balanceOf(address(this));
        return aTokenBalance > totalDeposited ? aTokenBalance - totalDeposited : 0;
    }
}