// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract LendingProtocol is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable lendingToken; // USDT
    
    uint256 public constant SUPPLY_APY = 2; // 2% APY for suppliers
    uint256 public constant BORROW_APY = 5; // 5% APY for borrowers
    uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization ratio
    uint256 public constant LIQUIDATION_THRESHOLD = 120; // 120% liquidation threshold
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    struct UserAccount {
        uint256 supplied;
        uint256 borrowed;
        uint256 collateral; // ETH/KAIA collateral
        uint256 lastSupplyUpdate;
        uint256 lastBorrowUpdate;
        uint256 accruedSupplyInterest;
        uint256 accruedBorrowInterest;
    }

    mapping(address => UserAccount) public accounts;
    
    uint256 public totalSupplied;
    uint256 public totalBorrowed;
    uint256 public totalCollateral;

    event Supplied(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address indexed liquidator, uint256 debtCovered, uint256 collateralSeized);

    constructor(address _lendingToken) Ownable(msg.sender) {
        lendingToken = IERC20(_lendingToken);
    }

    function supply(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        _updateInterest(msg.sender);
        
        lendingToken.safeTransferFrom(msg.sender, address(this), amount);
        
        UserAccount storage account = accounts[msg.sender];
        account.supplied += amount;
        account.lastSupplyUpdate = block.timestamp;
        
        totalSupplied += amount;
        
        emit Supplied(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        _updateInterest(msg.sender);
        
        UserAccount storage account = accounts[msg.sender];
        uint256 availableToWithdraw = account.supplied + account.accruedSupplyInterest;
        require(availableToWithdraw >= amount, "Insufficient balance");
        
        if (amount <= account.accruedSupplyInterest) {
            account.accruedSupplyInterest -= amount;
        } else {
            uint256 principalWithdraw = amount - account.accruedSupplyInterest;
            account.accruedSupplyInterest = 0;
            account.supplied -= principalWithdraw;
            totalSupplied -= principalWithdraw;
        }
        
        lendingToken.safeTransfer(msg.sender, amount);
        
        emit Withdrawn(msg.sender, amount);
    }

    function depositCollateral() external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Must deposit some collateral");
        
        UserAccount storage account = accounts[msg.sender];
        account.collateral += msg.value;
        totalCollateral += msg.value;
        
        emit CollateralDeposited(msg.sender, msg.value);
    }

    function withdrawCollateral(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        _updateInterest(msg.sender);
        
        UserAccount storage account = accounts[msg.sender];
        require(account.collateral >= amount, "Insufficient collateral");
        
        // Check if withdrawal would make account undercollateralized
        uint256 newCollateral = account.collateral - amount;
        uint256 totalDebt = account.borrowed + account.accruedBorrowInterest;
        
        if (totalDebt > 0) {
            // Assuming 1 ETH = 3000 USDT for collateral calculation
            uint256 maxBorrow = (newCollateral * 3000 * 100) / COLLATERAL_RATIO;
            require(totalDebt <= maxBorrow, "Would become undercollateralized");
        }
        
        account.collateral -= amount;
        totalCollateral -= amount;
        
        payable(msg.sender).transfer(amount);
        
        emit CollateralWithdrawn(msg.sender, amount);
    }

    function borrow(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= getAvailableBorrow(), "Insufficient protocol liquidity");
        
        _updateInterest(msg.sender);
        
        UserAccount storage account = accounts[msg.sender];
        
        // Check collateralization
        uint256 newTotalBorrow = account.borrowed + account.accruedBorrowInterest + amount;
        // Assuming 1 ETH = 3000 USDT for simplicity
        uint256 maxBorrow = (account.collateral * 3000 * 100) / COLLATERAL_RATIO;
        require(newTotalBorrow <= maxBorrow, "Insufficient collateral");
        
        account.borrowed += amount;
        account.lastBorrowUpdate = block.timestamp;
        totalBorrowed += amount;
        
        lendingToken.safeTransfer(msg.sender, amount);
        
        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        _updateInterest(msg.sender);
        
        UserAccount storage account = accounts[msg.sender];
        uint256 totalDebt = account.borrowed + account.accruedBorrowInterest;
        require(totalDebt > 0, "No debt to repay");
        
        uint256 repayAmount = amount > totalDebt ? totalDebt : amount;
        
        lendingToken.safeTransferFrom(msg.sender, address(this), repayAmount);
        
        if (repayAmount <= account.accruedBorrowInterest) {
            account.accruedBorrowInterest -= repayAmount;
        } else {
            uint256 principalRepay = repayAmount - account.accruedBorrowInterest;
            account.accruedBorrowInterest = 0;
            account.borrowed -= principalRepay;
            totalBorrowed -= principalRepay;
        }
        
        emit Repaid(msg.sender, repayAmount);
    }

    function liquidate(address user) external nonReentrant whenNotPaused {
        _updateInterest(user);
        
        UserAccount storage account = accounts[user];
        uint256 totalDebt = account.borrowed + account.accruedBorrowInterest;
        require(totalDebt > 0, "No debt to liquidate");
        
        // Check if account is undercollateralized (below liquidation threshold)
        uint256 collateralValue = account.collateral * 3000; // ETH price in USDT
        uint256 minCollateral = (totalDebt * LIQUIDATION_THRESHOLD) / 100;
        require(collateralValue < minCollateral, "Account is not liquidatable");
        
        // Liquidate entire position for simplicity
        uint256 collateralToSeize = account.collateral;
        uint256 debtToCover = totalDebt;
        
        // Transfer debt from liquidator
        lendingToken.safeTransferFrom(msg.sender, address(this), debtToCover);
        
        // Transfer collateral to liquidator
        payable(msg.sender).transfer(collateralToSeize);
        
        // Clear user's position
        account.borrowed = 0;
        account.accruedBorrowInterest = 0;
        account.collateral = 0;
        totalBorrowed -= account.borrowed;
        totalCollateral -= collateralToSeize;
        
        emit Liquidated(user, msg.sender, debtToCover, collateralToSeize);
    }

    function _updateInterest(address user) internal {
        UserAccount storage account = accounts[user];
        
        if (account.supplied > 0 && account.lastSupplyUpdate > 0) {
            uint256 timeElapsed = block.timestamp - account.lastSupplyUpdate;
            uint256 interest = (account.supplied * SUPPLY_APY * timeElapsed) / (100 * SECONDS_PER_YEAR);
            account.accruedSupplyInterest += interest;
            account.lastSupplyUpdate = block.timestamp;
        } else if (account.supplied > 0) {
            account.lastSupplyUpdate = block.timestamp;
        }
        
        if (account.borrowed > 0 && account.lastBorrowUpdate > 0) {
            uint256 timeElapsed = block.timestamp - account.lastBorrowUpdate;
            uint256 interest = (account.borrowed * BORROW_APY * timeElapsed) / (100 * SECONDS_PER_YEAR);
            account.accruedBorrowInterest += interest;
            account.lastBorrowUpdate = block.timestamp;
        } else if (account.borrowed > 0) {
            account.lastBorrowUpdate = block.timestamp;
        }
    }

    function getAccountInfo(address user) external view returns (
        uint256 supplied,
        uint256 borrowed, 
        uint256 collateral,
        uint256 pendingSupplyInterest,
        uint256 pendingBorrowInterest,
        bool isLiquidatable
    ) {
        UserAccount memory account = accounts[user];
        
        // Calculate pending interest
        uint256 supplyInterest = account.accruedSupplyInterest;
        uint256 borrowInterest = account.accruedBorrowInterest;
        
        if (account.supplied > 0 && account.lastSupplyUpdate > 0) {
            uint256 timeElapsed = block.timestamp - account.lastSupplyUpdate;
            supplyInterest += (account.supplied * SUPPLY_APY * timeElapsed) / (100 * SECONDS_PER_YEAR);
        }
        
        if (account.borrowed > 0 && account.lastBorrowUpdate > 0) {
            uint256 timeElapsed = block.timestamp - account.lastBorrowUpdate;
            borrowInterest += (account.borrowed * BORROW_APY * timeElapsed) / (100 * SECONDS_PER_YEAR);
        }
        
        // Check liquidation status
        uint256 totalDebt = account.borrowed + borrowInterest;
        bool liquidatable = false;
        if (totalDebt > 0) {
            uint256 collateralValue = account.collateral * 3000;
            uint256 minCollateral = (totalDebt * LIQUIDATION_THRESHOLD) / 100;
            liquidatable = collateralValue < minCollateral;
        }
        
        return (
            account.supplied,
            account.borrowed,
            account.collateral,
            supplyInterest,
            borrowInterest,
            liquidatable
        );
    }

    function getAvailableBorrow() public view returns (uint256) {
        uint256 available = lendingToken.balanceOf(address(this));
        return available > totalBorrowed ? available - totalBorrowed : 0;
    }

    function getUtilizationRate() external view returns (uint256) {
        if (totalSupplied == 0) return 0;
        return (totalBorrowed * 100) / totalSupplied;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    receive() external payable {
        require(msg.value > 0, "Must deposit some collateral");
        
        UserAccount storage account = accounts[msg.sender];
        account.collateral += msg.value;
        totalCollateral += msg.value;
        
        emit CollateralDeposited(msg.sender, msg.value);
    }
}