// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/investment/YieldStrategyManagerFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CreateYieldStrategyManager is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address factoryAddress = vm.envAddress("STRATEGY_FACTORY_ADDRESS");
        address usdc = vm.envAddress("USDC");
        string memory name = vm.envString("NAME");
        string memory symbol = vm.envString("SYMBOL");
        address aaveStrategy = vm.envAddress("AAVE_STRATEGY");
        address morphoStrategy = vm.envAddress("MORPHO_STRATEGY");
        address uniswapStrategy = vm.envAddress("UNISWAP_STRATEGY");
        uint256 aaveAllocation = vm.envUint("AAVE_ALLOCATION");
        uint256 morphoAllocation = vm.envUint("MORPHO_ALLOCATION");
        uint256 uniswapAllocation = vm.envUint("UNISWAP_ALLOCATION");

        YieldStrategyManagerFactory factory = YieldStrategyManagerFactory(factoryAddress);

        vm.startBroadcast(deployerPrivateKey);

        address strategyManagerAddress = factory.createStrategyManager(
            IERC20(usdc),
            name,
            symbol,
            aaveStrategy,
            morphoStrategy,
            uniswapStrategy,
            aaveAllocation,
            morphoAllocation,
            uniswapAllocation
        );

        console.log("YieldStrategyManager created at:", strategyManagerAddress);

        vm.stopBroadcast();
    }
}