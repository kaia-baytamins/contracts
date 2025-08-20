// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract USDTStaking is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken; // USDT
    
    uint256 public constant APY = 3; // 3% annual percentage yield
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    
    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 rewardDebt;
    }
    
    mapping(address => StakeInfo) public stakes;
    mapping(address => uint256) public claimedRewards;
    
    uint256 public totalStaked;
    uint256 public totalRewardsPaid;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(address _stakingToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
    }

    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        // Claim pending rewards before updating stake
        _claimRewards(msg.sender);
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        
        StakeInfo storage userStake = stakes[msg.sender];
        userStake.amount += amount;
        userStake.timestamp = block.timestamp;
        userStake.rewardDebt = 0; // Reset reward debt after claiming
        
        totalStaked += amount;
        
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant whenNotPaused {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient staked amount");
        
        // Claim pending rewards before unstaking
        _claimRewards(msg.sender);
        
        userStake.amount -= amount;
        userStake.timestamp = block.timestamp;
        userStake.rewardDebt = 0; // Reset reward debt after claiming
        
        totalStaked -= amount;
        
        stakingToken.safeTransfer(msg.sender, amount);
        
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external nonReentrant {
        _claimRewards(msg.sender);
    }

    function _claimRewards(address user) internal {
        uint256 pendingReward = calculateReward(user);
        if (pendingReward > 0) {
            StakeInfo storage userStake = stakes[user];
            userStake.rewardDebt += pendingReward;
            claimedRewards[user] += pendingReward;
            totalRewardsPaid += pendingReward;
            
            // For hackathon, we'll mint rewards directly
            // In production, this should come from a reward pool
            require(stakingToken.balanceOf(address(this)) >= pendingReward, "Insufficient reward balance");
            stakingToken.safeTransfer(user, pendingReward);
            
            emit RewardClaimed(user, pendingReward);
        }
    }

    function calculateReward(address user) public view returns (uint256) {
        StakeInfo memory userStake = stakes[user];
        if (userStake.amount == 0) {
            return 0;
        }
        
        uint256 timeStaked = block.timestamp - userStake.timestamp;
        uint256 annualReward = (userStake.amount * APY) / 100;
        uint256 reward = (annualReward * timeStaked) / SECONDS_PER_YEAR;
        
        return reward - userStake.rewardDebt;
    }

    function getStakeInfo(address user) external view returns (
        uint256 amount,
        uint256 timestamp,
        uint256 pendingReward,
        uint256 totalClaimed
    ) {
        StakeInfo memory userStake = stakes[user];
        return (
            userStake.amount,
            userStake.timestamp,
            calculateReward(user),
            claimedRewards[user]
        );
    }

    function getTotalStats() external view returns (
        uint256 _totalStaked,
        uint256 _totalRewardsPaid,
        uint256 totalUsers
    ) {
        // Note: totalUsers would need additional tracking in a real implementation
        return (totalStaked, totalRewardsPaid, 0);
    }

    // Admin functions
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw() external onlyOwner whenPaused {
        uint256 balance = stakingToken.balanceOf(address(this));
        stakingToken.safeTransfer(owner(), balance);
    }

    function fundRewards(uint256 amount) external onlyOwner {
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }
}