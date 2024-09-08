// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/crossChain/ChainLinkCross.sol";

contract DeployCrossChainManager is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ccipRouter = vm.envAddress("CCIP_ROUTER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        ProtocolCrossChainManager crossChainManager = new ProtocolCrossChainManager(
            msg.sender,
            ccipRouter
        );

        console.log("ProtocolCrossChainManager deployed at:", address(crossChainManager));

        vm.stopBroadcast();
    }
}