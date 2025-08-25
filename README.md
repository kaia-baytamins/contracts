## 🚀 Deployed Contracts (KAIA Testnet)

| Contract | Address | Description |
|---------|---------|-------------|
| **USDT Token** | `0x6283D8384d8F6eAF24eC44D355F31CEC0bDacE3D` | ERC20 token (1M initial supply) |
| **USDT Staking** | `0x492b504EF0f81E52622087Eeb88124de8F2e4819` | 3% APY staking contract |
| **SimpleAMM** | `0x5D2CAB3a1263a28764d001180F300eaEeCDfb344` | KAIA-USDT AMM (0.3% fee) |
| **Lending Protocol** | `0xD24c75020E9FE0763473D4d313AA16955dA84468` | Supply 2%, Borrow 5% APY |
| **USDT Faucet** | `0x4E2eBac253D77900CC50DD093f17150Ba4437FaE` | 1000 USDT every 10 minutes |
| **Inventory** | `0xA5A26A9B9E7e1D9eC4304Ba0D1c2E6c9f9Cd9104` | item inventory contract(ERC-1155) |

### Network Information
- **Chain ID**: 1001 (KAIA Testnet)
- **RPC URL**: https://public-en-kairos.node.kaia.io
- **Explorer**: https://kairos.kaiascope.com/

### Staking System
- Stake USDT to increase animal stats
- 3% annual percentage yield
- Real-time interest calculation

### AMM (Automated Market Maker)
- KAIA ↔ USDT swaps
- Liquidity provision for fee rewards
- Constant product formula (x×y=k)

### Lending Protocol
- Borrow USDT with ETH/KAIA collateral
- 150% collateral ratio, 120% liquidation threshold
- Suppliers earn 2% APY, borrowers pay 5% APY

### Faucet
- Free 1000 USDT every 10 minutes
- Test token distribution

### Inventory 
- **item Categories**: Items are divided into four categories based on their ID range:
    - **0–15**: Engine – Components for spaceship propulsion.
    - **16–31**: Spaceship Materials – Construction and upgrade supplies.
    - **32–47**: Special Equipment – Advanced tools and devices.
    - **48–63**: Fuel – Energy sources for spaceship operation.
- **Rarity Levels**: Each category contains items with different rarity:
    - **8 Common items**
    - **5 Rare items**
    - **3 Legendary items**

## 🛠 Development

### Build
```bash
forge build
```

### Test
```bash
forge test
```

### Deploy
```bash
forge script script/Deploy.s.sol --rpc-url kaia_testnet --broadcast
```

## 📊 Contract Functions

### USDT Token
- Standard ERC20 with minting capabilities
- Role-based access control
- Pausable for emergencies

### USDTStaking
- `stake(amount)`: Stake USDT tokens
- `unstake(amount)`: Unstake tokens
- `claimRewards()`: Claim accumulated rewards
- `calculateReward(user)`: View pending rewards

### SimpleAMM
- `addLiquidity(amountA, amountB)`: Add liquidity
- `removeLiquidity(liquidity)`: Remove liquidity
- `swapAForB(amountIn)`: KAIA → USDT
- `swapBForA(amountIn)`: USDT → KAIA

### LendingProtocol
- `supply(amount)`: Deposit USDT
- `withdraw(amount)`: Withdraw deposits
- `depositCollateral()`: Deposit ETH collateral
- `borrow(amount)`: Borrow USDT
- `repay(amount)`: Repay loans

### USDTFaucet
- `claimTokens()`: Get 1000 USDT (10min cooldown)
- `canClaim(user)`: Check if user can claim

### Inventory
- `mintItems(to, itemIds[], amount[])`: **batch** mint (Admin only).
- `mintItem(to, itemId, amount)`: single mint (Admin only).
- `useItems(user, itemIds[], amounts[])`: **batch** burn (Admin only).
- `useItem(user, itemId, amount)`: single burn (Admin only).
- `getUserItems(user, itemIds[])`: Get item balances for a user based on item IDs. 

## 🔒 Security Features

- **ReentrancyGuard**: Protection against reentrancy attacks
- **AccessControl**: Role-based permission system
- **Pausable**: Emergency stop functionality
- **SafeERC20**: Safe token transfers

Built with OpenZeppelin contracts for maximum security and reliability.