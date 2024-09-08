// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/investment/YieldStrategyManagerFactory.sol";
import "../src/investment/strategies/AaveYieldStrategy.sol";
import "../src/investment/strategies/MorphoYieldStrategy.sol";
import "../src/investment/strategies/UniswapYieldStrategy.sol";

contract DeployYieldStrategies is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address aavePool = vm.envAddress("AAVE_POOL");
        address aaveAToken = vm.envAddress("AAVE_ATOKEN");
        address morphoVault = vm.envAddress("MORPHO_VAULT");
        address usdc = vm.envAddress("USDC");
        address weth = vm.envAddress("WETH");
        address uniswapPool = vm.envAddress("UNISWAP_POOL");
        address uniswapNFTMgr = vm.envAddress("UNISWAP_NFTMGR");
        address uniswapRouter = vm.envAddress("UNISWAP_ROUTER");
        uint256 uniswapFee = vm.envUint("UNISWAP_FEE");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy yield strategy contracts
        AaveYieldStrategy aaveStrategy = new AaveYieldStrategy(aavePool, aaveAToken, msg.sender);
        MorphoYieldStrategy morphoStrategy = new MorphoYieldStrategy(usdc, morphoVault, msg.sender);
        UniswapYieldStrategy uniswapStrategy = new UniswapYieldStrategy(usdc, weth, uniswapPool, uniswapNFTMgr, uniswapRouter, uint24(uniswapFee), msg.sender);

        // Deploy YieldStrategyManagerFactory
        YieldStrategyManagerFactory factory = new YieldStrategyManagerFactory(msg.sender);

        console.log("AaveYieldStrategy deployed at:", address(aaveStrategy));
        console.log("MorphoYieldStrategy deployed at:", address(morphoStrategy));
        console.log("UniswapYieldStrategy deployed at:", address(uniswapStrategy));
        console.log("YieldStrategyManagerFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}