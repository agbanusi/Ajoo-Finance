// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./YieldStrategyManager.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";


contract YieldStrategyManagerFactory is Ownable {
     bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    event StrategyManagerCreated(address indexed strategyManager, address indexed asset);

    constructor(address initialOwner) Ownable(initialOwner){
        transferOwnership(initialOwner);
    }

    function createStrategyManager(
        IERC20 asset,
        string memory name,
        string memory symbol,
        address aaveStrategy,
        address morphoStrategy,
        address uniswapStrategy,
        uint256 aaveAllocation,
        uint256 morphoAllocation,
        uint256 uniswapAllocation
    ) external returns (address) {
        YieldStrategyManager newStrategyManager = new YieldStrategyManager(
            asset,
            name,
            symbol,
            aaveStrategy,
            morphoStrategy,
            uniswapStrategy,
            aaveAllocation,
            morphoAllocation,
            uniswapAllocation,
            msg.sender
        );

        IAccessControl(aaveStrategy).grantRole(USER_ROLE, address(newStrategyManager));
        IAccessControl(morphoStrategy).grantRole(USER_ROLE, address(newStrategyManager));
        IAccessControl(uniswapStrategy).grantRole(USER_ROLE, address(newStrategyManager));

        emit StrategyManagerCreated(address(newStrategyManager), address(asset));

        return address(newStrategyManager);
    }
}