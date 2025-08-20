// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/USDT.sol";
import "../src/SimpleAMM.sol";

contract MockKAIA is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply = 1000000 * 10**18;

    constructor() {
        _balances[msg.sender] = _totalSupply;
    }

    function totalSupply() external view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) external view returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) external view returns (uint256) { return _allowances[owner][spender]; }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "Insufficient allowance");
        require(_balances[from] >= amount, "Insufficient balance");
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        return true;
    }

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
    }
}

contract SimpleAMMTest is Test {
    USDT public usdt;
    MockKAIA public kaia;
    SimpleAMM public amm;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    uint256 public constant INITIAL_BALANCE = 10000 * 10**18;

    function setUp() public {
        usdt = new USDT();
        kaia = new MockKAIA();
        amm = new SimpleAMM(address(kaia), address(usdt));
        
        // Mint tokens to users
        usdt.mint(user1, INITIAL_BALANCE);
        usdt.mint(user2, INITIAL_BALANCE);
        kaia.mint(user1, INITIAL_BALANCE);
        kaia.mint(user2, INITIAL_BALANCE);
    }

    function testAddLiquidity() public {
        uint256 kaiaAmount = 1000 * 10**18;
        uint256 usdtAmount = 3000 * 10**18; // 1 KAIA = 3 USDT
        
        vm.startPrank(user1);
        kaia.approve(address(amm), kaiaAmount);
        usdt.approve(address(amm), usdtAmount);
        
        (uint256 actualKaia, uint256 actualUsdt, uint256 liquidity) = amm.addLiquidity(kaiaAmount, usdtAmount);
        vm.stopPrank();
        
        assertEq(actualKaia, kaiaAmount);
        assertEq(actualUsdt, usdtAmount);
        assertGt(liquidity, 0);
        assertEq(amm.getUserLiquidity(user1), liquidity);
        
        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        assertEq(reserveA, kaiaAmount);
        assertEq(reserveB, usdtAmount);
    }

    function testSwap() public {
        // First add liquidity
        uint256 kaiaAmount = 1000 * 10**18;
        uint256 usdtAmount = 3000 * 10**18;
        
        vm.startPrank(user1);
        kaia.approve(address(amm), kaiaAmount);
        usdt.approve(address(amm), usdtAmount);
        amm.addLiquidity(kaiaAmount, usdtAmount);
        vm.stopPrank();
        
        // User2 swaps KAIA for USDT
        uint256 swapAmount = 10 * 10**18; // 10 KAIA
        
        vm.startPrank(user2);
        kaia.approve(address(amm), swapAmount);
        uint256 usdtReceived = amm.swapAForB(swapAmount);
        vm.stopPrank();
        
        assertGt(usdtReceived, 0);
        assertLt(usdtReceived, 30 * 10**18); // Should be less than 30 USDT due to price impact and fees
    }

    function testRemoveLiquidity() public {
        // Add liquidity first
        uint256 kaiaAmount = 1000 * 10**18;
        uint256 usdtAmount = 3000 * 10**18;
        
        vm.startPrank(user1);
        kaia.approve(address(amm), kaiaAmount);
        usdt.approve(address(amm), usdtAmount);
        (, , uint256 liquidity) = amm.addLiquidity(kaiaAmount, usdtAmount);
        
        uint256 kaiaBalanceBefore = kaia.balanceOf(user1);
        uint256 usdtBalanceBefore = usdt.balanceOf(user1);
        
        // Remove half the liquidity
        uint256 liquidityToRemove = liquidity / 2;
        (uint256 kaiaOut, uint256 usdtOut) = amm.removeLiquidity(liquidityToRemove);
        vm.stopPrank();
        
        assertGt(kaiaOut, 0);
        assertGt(usdtOut, 0);
        assertEq(kaia.balanceOf(user1), kaiaBalanceBefore + kaiaOut);
        assertEq(usdt.balanceOf(user1), usdtBalanceBefore + usdtOut);
    }

    function testGetAmountOut() public {
        uint256 amountIn = 10 * 10**18;
        uint256 reserveIn = 1000 * 10**18;
        uint256 reserveOut = 3000 * 10**18;
        
        uint256 amountOut = amm.getAmountOut(amountIn, reserveIn, reserveOut);
        assertGt(amountOut, 0);
        assertLt(amountOut, 30 * 10**18); // Less than 30 due to fees
    }

    function test_RevertWhen_SwapWithoutLiquidity() public {
        vm.startPrank(user1);
        kaia.approve(address(amm), 10 * 10**18);
        vm.expectRevert("Insufficient liquidity");
        amm.swapAForB(10 * 10**18);
        vm.stopPrank();
    }
}