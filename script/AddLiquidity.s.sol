// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/SimpleAMM.sol";

contract AddLiquidityScript is Script {
    // Deployed contract addresses on KAIA Testnet
    address constant WKAIA_ADDRESS = 0x043c471bEe060e00A56CcD02c0Ca286808a5A436;   // WKAIA on Kairos testnet
    address constant USDT_ADDRESS = 0x6283D8384d8F6eAF24eC44D355F31CEC0bDacE3D;    // USDT from README
    address constant AMM_ADDRESS = 0x8cc13474301FE5AA08c920dB228A3BB1E68F5b13;     // New SimpleAMM with WKAIA
    
    // Amounts to add
    uint256 constant WKAIA_AMOUNT = 10 * 10**18;    // 10 WKAIA (18 decimals)
    uint256 constant USDT_AMOUNT = 1000 * 10**18;   // 1000 USDT (18 decimals)
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        IERC20 wkaia = IERC20(WKAIA_ADDRESS);
        IERC20 usdt = IERC20(USDT_ADDRESS);
        SimpleAMM amm = SimpleAMM(AMM_ADDRESS);
        
        address user = vm.addr(deployerPrivateKey);
        console.log("Adding liquidity from user:", user);
        console.log("User native balance:", user.balance);
        console.log("User WKAIA balance:", wkaia.balanceOf(user));
        console.log("User USDT balance:", usdt.balanceOf(user));
        
        // Check if user has enough balance
        require(wkaia.balanceOf(user) >= WKAIA_AMOUNT, "Insufficient WKAIA balance");
        require(usdt.balanceOf(user) >= USDT_AMOUNT, "Insufficient USDT balance");
        
        // Approve token spending for AMM
        console.log("Approving WKAIA spending...");
        wkaia.approve(AMM_ADDRESS, WKAIA_AMOUNT);
        console.log("Approving USDT spending...");
        usdt.approve(AMM_ADDRESS, USDT_AMOUNT);
        
        // Check current reserves before adding liquidity
        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        console.log("Current WKAIA reserve:", reserveA);
        console.log("Current USDT reserve:", reserveB);
        
        // Add liquidity
        console.log("Adding liquidity...");
        console.log("WKAIA amount:", WKAIA_AMOUNT);
        console.log("USDT amount:", USDT_AMOUNT);
        
        (uint256 actualWkaia, uint256 actualUsdt, uint256 liquidity) = amm.addLiquidity(
            WKAIA_AMOUNT,
            USDT_AMOUNT
        );
        
        console.log("\n=== Liquidity Added Successfully ===");
        console.log("Actual WKAIA used:", actualWkaia);
        console.log("Actual USDT used:", actualUsdt);
        console.log("LP tokens received:", liquidity);
        
        // Check reserves after adding liquidity
        (uint256 newReserveA, uint256 newReserveB) = amm.getReserves();
        console.log("New WKAIA reserve:", newReserveA);
        console.log("New USDT reserve:", newReserveB);
        
        // Check user's LP balance
        uint256 userLiquidity = amm.getUserLiquidity(user);
        console.log("User LP balance:", userLiquidity);
        
        vm.stopBroadcast();
    }
    
    // Helper function to add liquidity with custom amounts
    function addLiquidityCustom(uint256 wkaiaAmount, uint256 usdtAmount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        IERC20 wkaia = IERC20(WKAIA_ADDRESS);
        IERC20 usdt = IERC20(USDT_ADDRESS);
        SimpleAMM amm = SimpleAMM(AMM_ADDRESS);
        
        address user = vm.addr(deployerPrivateKey);
        
        // Approve token spending
        wkaia.approve(AMM_ADDRESS, wkaiaAmount);
        usdt.approve(AMM_ADDRESS, usdtAmount);
        
        // Add liquidity
        (uint256 actualWkaia, uint256 actualUsdt, uint256 liquidity) = amm.addLiquidity(
            wkaiaAmount,
            usdtAmount
        );
        
        console.log("Actual WKAIA used:", actualWkaia);
        console.log("Actual USDT used:", actualUsdt);
        console.log("LP tokens received:", liquidity);
        
        vm.stopBroadcast();
    }
}