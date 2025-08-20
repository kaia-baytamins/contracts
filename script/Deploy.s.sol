// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/USDT.sol";
import "../src/USDTStaking.sol";
import "../src/SimpleAMM.sol";
import "../src/LendingProtocol.sol";
import "../src/USDTFaucet.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy USDT token
        USDT usdt = new USDT();
        console.log("USDT deployed at:", address(usdt));

        // Deploy Staking contract
        USDTStaking staking = new USDTStaking(address(usdt));
        console.log("USDTStaking deployed at:", address(staking));

        // Deploy AMM (assuming KAIA is native token, using address(0) as placeholder)
        SimpleAMM amm = new SimpleAMM(address(0), address(usdt)); // KAIA-USDT pair
        console.log("SimpleAMM deployed at:", address(amm));

        // Deploy Lending Protocol
        LendingProtocol lending = new LendingProtocol(address(usdt));
        console.log("LendingProtocol deployed at:", address(lending));

        // Deploy Faucet
        USDTFaucet faucet = new USDTFaucet(address(usdt));
        console.log("USDTFaucet deployed at:", address(faucet));

        // Grant MINTER_ROLE to faucet
        usdt.grantRole(usdt.MINTER_ROLE(), address(faucet));

        // Optional: Grant some USDT to contracts for initial liquidity
        usdt.mint(address(staking), 10000 * 10**18); // 10k USDT for staking rewards
        usdt.mint(address(lending), 50000 * 10**18); // 50k USDT for lending pool

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("USDT Token:", address(usdt));
        console.log("USDT Staking:", address(staking));
        console.log("AMM (KAIA-USDT):", address(amm));
        console.log("Lending Protocol:", address(lending));
        console.log("USDT Faucet:", address(faucet));
    }
}