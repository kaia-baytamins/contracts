// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SimpleAMM.sol";

contract DeployCorrectAMMScript is Script {
    address constant WKAIA_ADDRESS = 0x043c471bEe060e00A56CcD02c0Ca286808a5A436;   // WKAIA on Kairos testnet
    address constant USDT_ADDRESS = 0x6283D8384d8F6eAF24eC44D355F31CEC0bDacE3D;    // USDT from README
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy AMM with correct WKAIA address
        SimpleAMM amm = new SimpleAMM(WKAIA_ADDRESS, USDT_ADDRESS);
        console.log("New SimpleAMM deployed at:", address(amm));
        console.log("TokenA (WKAIA):", WKAIA_ADDRESS);
        console.log("TokenB (USDT):", USDT_ADDRESS);
        
        vm.stopBroadcast();
    }
}