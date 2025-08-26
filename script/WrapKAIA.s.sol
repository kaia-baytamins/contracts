// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IWKAIA {
    function deposit() external payable;
    function balanceOf(address account) external view returns (uint256);
}

contract WrapKAIAScript is Script {
    address constant WKAIA_ADDRESS = 0x043c471bEe060e00A56CcD02c0Ca286808a5A436;
    uint256 constant KAIA_TO_WRAP = 10 * 10**18; // 10 KAIA
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        IWKAIA wkaia = IWKAIA(WKAIA_ADDRESS);
        address user = vm.addr(deployerPrivateKey);
        
        console.log("Wrapping KAIA for user:", user);
        console.log("User native KAIA balance:", user.balance);
        console.log("KAIA to wrap:", KAIA_TO_WRAP);
        
        require(user.balance >= KAIA_TO_WRAP, "Insufficient KAIA balance");
        
        // Check WKAIA balance before wrapping
        uint256 wkaiaBalanceBefore = wkaia.balanceOf(user);
        console.log("WKAIA balance before:", wkaiaBalanceBefore);
        
        // Wrap KAIA to WKAIA
        wkaia.deposit{value: KAIA_TO_WRAP}();
        
        // Check WKAIA balance after wrapping
        uint256 wkaiaBalanceAfter = wkaia.balanceOf(user);
        console.log("WKAIA balance after:", wkaiaBalanceAfter);
        console.log("WKAIA received:", wkaiaBalanceAfter - wkaiaBalanceBefore);
        
        vm.stopBroadcast();
    }
}