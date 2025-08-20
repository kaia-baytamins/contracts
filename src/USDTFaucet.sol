// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./USDT.sol";

contract USDTFaucet is Ownable, Pausable {
    USDT public immutable usdtToken;
    
    uint256 public constant FAUCET_AMOUNT = 1000 * 10**18; // 1000 USDT per request
    uint256 public constant COOLDOWN_PERIOD = 10 minutes;
    
    mapping(address => uint256) public lastClaimTime;
    
    event TokensClaimed(address indexed user, uint256 amount);
    
    constructor(address _usdtToken) Ownable(msg.sender) {
        usdtToken = USDT(_usdtToken);
    }
    
    function claimTokens() external whenNotPaused {
        require(
            block.timestamp >= lastClaimTime[msg.sender] + COOLDOWN_PERIOD,
            "Cooldown period not met"
        );
        
        lastClaimTime[msg.sender] = block.timestamp;
        usdtToken.mint(msg.sender, FAUCET_AMOUNT);
        
        emit TokensClaimed(msg.sender, FAUCET_AMOUNT);
    }
    
    function getNextClaimTime(address user) external view returns (uint256) {
        return lastClaimTime[user] + COOLDOWN_PERIOD;
    }
    
    function canClaim(address user) external view returns (bool) {
        return block.timestamp >= lastClaimTime[user] + COOLDOWN_PERIOD;
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
}