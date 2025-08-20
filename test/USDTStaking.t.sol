// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/USDT.sol";
import "../src/USDTStaking.sol";

contract USDTStakingTest is Test {
    USDT public usdt;
    USDTStaking public staking;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    uint256 public constant INITIAL_BALANCE = 1000 * 10**18;

    function setUp() public {
        usdt = new USDT();
        staking = new USDTStaking(address(usdt));
        
        // Mint tokens to users
        usdt.mint(user1, INITIAL_BALANCE);
        usdt.mint(user2, INITIAL_BALANCE);
        
        // Fund staking contract for rewards
        usdt.mint(address(staking), 10000 * 10**18);
    }

    function testStaking() public {
        uint256 stakeAmount = 100 * 10**18; // 100 USDT
        
        vm.startPrank(user1);
        usdt.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();
        
        (uint256 amount, uint256 timestamp, uint256 pendingReward, uint256 totalClaimed) = staking.getStakeInfo(user1);
        
        assertEq(amount, stakeAmount);
        assertEq(timestamp, block.timestamp);
        assertEq(pendingReward, 0); // No time passed yet
    }

    function testRewardCalculation() public {
        uint256 stakeAmount = 100 * 10**18; // 100 USDT
        
        vm.startPrank(user1);
        usdt.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();
        
        // Fast forward 1 year
        vm.warp(block.timestamp + 365 days);
        
        uint256 expectedReward = (stakeAmount * 3) / 100; // 3% APY
        uint256 actualReward = staking.calculateReward(user1);
        
        // Allow small precision differences
        assertApproxEqRel(actualReward, expectedReward, 0.01e18); // 1% tolerance
    }

    function testUnstaking() public {
        uint256 stakeAmount = 100 * 10**18;
        
        vm.startPrank(user1);
        usdt.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        
        // Fast forward some time
        vm.warp(block.timestamp + 30 days);
        
        uint256 balanceBefore = usdt.balanceOf(user1);
        uint256 pendingReward = staking.calculateReward(user1);
        
        staking.unstake(stakeAmount);
        vm.stopPrank();
        
        uint256 balanceAfter = usdt.balanceOf(user1);
        assertEq(balanceAfter, balanceBefore + stakeAmount + pendingReward);
        
        (uint256 amount, , , ) = staking.getStakeInfo(user1);
        assertEq(amount, 0);
    }

    function testMultipleUsers() public {
        uint256 stake1 = 100 * 10**18;
        uint256 stake2 = 200 * 10**18;
        
        // User1 stakes
        vm.startPrank(user1);
        usdt.approve(address(staking), stake1);
        staking.stake(stake1);
        vm.stopPrank();
        
        // User2 stakes
        vm.startPrank(user2);
        usdt.approve(address(staking), stake2);
        staking.stake(stake2);
        vm.stopPrank();
        
        (uint256 amount1, , , ) = staking.getStakeInfo(user1);
        (uint256 amount2, , , ) = staking.getStakeInfo(user2);
        
        assertEq(amount1, stake1);
        assertEq(amount2, stake2);
        
        (uint256 totalStaked, , ) = staking.getTotalStats();
        assertEq(totalStaked, stake1 + stake2);
    }

    function test_RevertWhen_StakeZero() public {
        vm.startPrank(user1);
        usdt.approve(address(staking), 0);
        vm.expectRevert("Amount must be greater than 0");
        staking.stake(0);
        vm.stopPrank();
    }

    function test_RevertWhen_UnstakeMoreThanStaked() public {
        uint256 stakeAmount = 100 * 10**18;
        
        vm.startPrank(user1);
        usdt.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.expectRevert("Insufficient staked amount");
        staking.unstake(stakeAmount + 1);
        vm.stopPrank();
    }
}