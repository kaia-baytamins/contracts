// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract SimpleAMM is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable tokenA; // KAIA
    IERC20 public immutable tokenB; // USDT

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLiquidity;
    
    uint256 public constant FEE_PERCENT = 30; // 0.3% trading fee
    uint256 public constant FEE_DENOMINATOR = 10000;

    mapping(address => uint256) public liquidityBalances;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Swap(address indexed user, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountADesired, uint256 amountBDesired) 
        external 
        nonReentrant 
        whenNotPaused 
        returns (uint256 amountA, uint256 amountB, uint256 liquidity) 
    {
        require(amountADesired > 0 && amountBDesired > 0, "Invalid amounts");

        if (totalLiquidity == 0) {
            // First liquidity provision
            amountA = amountADesired;
            amountB = amountBDesired;
            liquidity = _sqrt(amountA * amountB);
        } else {
            // Calculate optimal amounts based on current ratio
            uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
            if (amountBOptimal <= amountBDesired) {
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
            
            liquidity = _min(
                (amountA * totalLiquidity) / reserveA,
                (amountB * totalLiquidity) / reserveB
            );
        }

        require(liquidity > 0, "Insufficient liquidity minted");

        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenB.safeTransferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;
        totalLiquidity += liquidity;
        liquidityBalances[msg.sender] += liquidity;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    function removeLiquidity(uint256 liquidity) 
        external 
        nonReentrant 
        whenNotPaused 
        returns (uint256 amountA, uint256 amountB) 
    {
        require(liquidity > 0, "Invalid liquidity amount");
        require(liquidityBalances[msg.sender] >= liquidity, "Insufficient liquidity balance");

        amountA = (liquidity * reserveA) / totalLiquidity;
        amountB = (liquidity * reserveB) / totalLiquidity;

        require(amountA > 0 && amountB > 0, "Insufficient liquidity burned");

        liquidityBalances[msg.sender] -= liquidity;
        totalLiquidity -= liquidity;
        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.safeTransfer(msg.sender, amountA);
        tokenB.safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
    }

    function swapAForB(uint256 amountAIn) external nonReentrant whenNotPaused returns (uint256 amountBOut) {
        require(amountAIn > 0, "Invalid input amount");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");

        // Apply trading fee
        uint256 amountAInWithFee = amountAIn * (FEE_DENOMINATOR - FEE_PERCENT) / FEE_DENOMINATOR;
        
        // Calculate output using constant product formula: x * y = k
        amountBOut = (amountAInWithFee * reserveB) / (reserveA + amountAInWithFee);
        require(amountBOut > 0, "Insufficient output amount");
        require(amountBOut < reserveB, "Insufficient liquidity");

        tokenA.safeTransferFrom(msg.sender, address(this), amountAIn);
        tokenB.safeTransfer(msg.sender, amountBOut);

        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit Swap(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    function swapBForA(uint256 amountBIn) external nonReentrant whenNotPaused returns (uint256 amountAOut) {
        require(amountBIn > 0, "Invalid input amount");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");

        // Apply trading fee
        uint256 amountBInWithFee = amountBIn * (FEE_DENOMINATOR - FEE_PERCENT) / FEE_DENOMINATOR;
        
        // Calculate output using constant product formula
        amountAOut = (amountBInWithFee * reserveA) / (reserveB + amountBInWithFee);
        require(amountAOut > 0, "Insufficient output amount");
        require(amountAOut < reserveA, "Insufficient liquidity");

        tokenB.safeTransferFrom(msg.sender, address(this), amountBIn);
        tokenA.safeTransfer(msg.sender, amountAOut);

        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit Swap(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) 
        public 
        pure 
        returns (uint256 amountOut) 
    {
        require(amountIn > 0, "Invalid input amount");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");

        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_PERCENT) / FEE_DENOMINATOR;
        amountOut = (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);
    }

    function getReserves() external view returns (uint256 _reserveA, uint256 _reserveB) {
        return (reserveA, reserveB);
    }

    function getUserLiquidity(address user) external view returns (uint256) {
        return liquidityBalances[user];
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw() external onlyOwner whenPaused {
        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenB.balanceOf(address(this));
        
        if (balanceA > 0) tokenA.safeTransfer(owner(), balanceA);
        if (balanceB > 0) tokenB.safeTransfer(owner(), balanceB);
    }
}