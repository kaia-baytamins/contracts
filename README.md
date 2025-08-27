## 🚀 Deployed Contracts (KAIA Testnet)

| Contract | Address | Description |
|---------|---------|-------------|
| **USDT Token** | `0x6283D8384d8F6eAF24eC44D355F31CEC0bDacE3D` | ERC20 token (1M initial supply) |
| **USDT Staking** | `0x492b504EF0f81E52622087Eeb88124de8F2e4819` | 3% APY staking contract |
| **SimpleAMM** | `0x8cc13474301FE5AA08c920dB228A3BB1E68F5b13` | WKAIA-USDT AMM (0.3% fee) |
| **Lending Protocol** | `0xD24c75020E9FE0763473D4d313AA16955dA84468` | Supply 2%, Borrow 5% APY |
| **USDT Faucet** | `0x4E2eBac253D77900CC50DD093f17150Ba4437FaE` | 1000 USDT every 10 minutes |
| **Inventory** | `0xa0823f73d9DB11ED559FCC43e76450eB6954Fc5c` | item inventory contract(ERC-1155) |
| **NFT Market** | `0x9f191C5E45731e1932EF5133C1300b13956E6ac1` | item trading contract (ERC-1155) |
| **Moon NFT** | `0x614B411f696bbB4322ed2d736122382D021b2628` | Moon Exploration Success NFT (ERC-721) |
| **Mars NFT** | `0xD83445678DBa146DaC44F35ecBd4BA91B6a03b9e` | Mars Exploration Success NFT (ERC-721) |
| **Titan NFT** | `0x5B2CE3c212B3Ec116C5f4Eef1e4FF8244E917527` | Titan Exploration Success NFT (ERC-721) |
| **Europa NFT** | `0xaA337a270E83fcb8Ff5579aEde83eEe6F6697463` | Europa Exploration Success NFT (ERC-721) |
| **Saturn NFT** | `0xd07CC716639eC0D8d1AA703D44177EB59aA8A502` | Saturn Exploration Success NFT (ERC-721) |



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
    - **4 Rare items**
    - **3 Epic items**
    - **1 Legendary items**

### NFTMarket
- Listing ERC1155 tokens for sale
- Purchasing listed items by paying the sepcified price in USDT
- Canceling their listed items

### Planet NFT (ERC721) 
- Mint NFTs for successful planetary explorations.
- Supports multiple planets (e.g., Moon, Titan, Europa, Saturn).
- Complies with the ERC721 standard for non-fungible tokens.

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
- `useItems(uint256[] itemIds[], uint256[] amounts[], uint nftNumber)`: **batch** burn (Admin only).
- `useItem(uint256 itemId, uint256 amount, uint256 nftNumber)`: single burn (Admin only).
- `getUserItems(user, itemIds[])`: Get item balances for a user based on item IDs. 
- nftNumber = [moon, mars, titan, europa, saturn]

### NFTMarket
- `listItem(itemId, amount, price)`: Allows a user to list their ERC1155 tokens for sale.
- `purchaseItem(listingId)`: Allows a buyer to purchase an item from a listing.
- `cancelListing(listingId)`: Allows the seller to cancel their active listing.

## 🔒 Security Features

- **ReentrancyGuard**: Protection against reentrancy attacks
- **AccessControl**: Role-based permission system
- **Pausable**: Emergency stop functionality
- **SafeERC20**: Safe token transfers

Built with OpenZeppelin contracts for maximum security and reliability.