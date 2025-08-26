// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "forge-std/Script.sol";
import "../src/Multicall3.sol";

contract DeployMulticall3Script is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Multicall3
        Multicall3 multicall3 = new Multicall3();

        console.log("Multicall3 deployed to:", address(multicall3));

        vm.stopBroadcast();
    }
}