# SimpleSwap
TPETHSimpleSwap
# SimpleSwap Smart Contract

A decentralized exchange (DEX) smart contract that replicates Uniswap functionality without depending on the Uniswap protocol. SimpleSwap enables automated market making (AMM) between two ERC-20 tokens: EKA and EKB.

## 🌟 Features

- **Automated Market Maker (AMM)**: Uses constant product formula (x * y = k)
- **Liquidity Management**: Add and remove liquidity with slippage protection
- **Token Swapping**: Exchange tokens with minimal price impact
- **Price Discovery**: Real-time price calculation based on reserves
- **Fee Structure**: 0.3% trading fee on all swaps
- **Deadline Protection**: Time-based transaction validation
- **Event Emission**: Comprehensive logging for transparency

## 🛠️ Architecture

### Supported Tokens
- **Token A**: EKA (First token in the pair)
- **Token B**: EKB (Second token in the pair)

### Core Components
- **Reserves**: Track token balances in the liquidity pool
- **Liquidity Shares**: Represent ownership stakes in the pool
- **Price Oracle**: Calculate real-time exchange rates
- **Fee System**: Automated fee collection on trades

## 📋 Contract Interface

### Core Functions

#### 1. Add Liquidity
```solidity
function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)
```

**Purpose**: Add liquidity to the ERC-20 token pair pool

**Parameters**:
- `tokenA`, `tokenB`: Token contract addresses (must be EKA/EKB)
- `amountADesired`, `amountBDesired`: Desired amounts to deposit
- `amountAMin`, `amountBMin`: Minimum acceptable amounts (slippage protection)
- `to`: Recipient address for liquidity tokens
- `deadline`: Transaction expiration timestamp

**Returns**:
- `amountA`, `amountB`: Actual amounts added to the pool
- `liquidity`: Amount of liquidity shares minted

**Process**:
1. Validates token addresses and parameters
2. Calculates optimal amounts maintaining pool ratio
3. Transfers tokens from user to contract
4. Mints liquidity shares proportional to contribution
5. Updates reserve balances

#### 2. Remove Liquidity
```solidity
function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
) external returns (uint256 amountA, uint256 amountB)
```

**Purpose**: Remove liquidity from the token pair pool

**Parameters**:
- `tokenA`, `tokenB`: Token contract addresses
- `liquidity`: Amount of liquidity shares to burn
- `amountAMin`, `amountBMin`: Minimum acceptable token amounts
- `to`: Recipient address for withdrawn tokens
- `deadline`: Transaction expiration timestamp

**Returns**:
- `amountA`, `amountB`: Amounts of tokens withdrawn

**Process**:
1. Validates user's liquidity share ownership
2. Calculates proportional token amounts
3. Burns liquidity shares
4. Transfers tokens back to user
5. Updates reserve balances

#### 3. Swap Tokens
```solidity
function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
) external returns (uint256[] memory amounts)
```

**Purpose**: Exchange exact amount of input tokens for output tokens

**Parameters**:
- `amountIn`: Exact amount of input tokens to swap
- `amountOutMin`: Minimum acceptable output amount (slippage protection)
- `path`: Array of token addresses [tokenIn, tokenOut]
- `to`: Recipient address for output tokens
- `deadline`: Transaction expiration timestamp

**Returns**:
- `amounts`: Array containing [amountIn, amountOut]

**Process**:
1. Validates input parameters and token addresses
2. Calculates output amount using constant product formula
3. Applies 0.3% trading fee
4. Transfers input tokens from user
5. Updates reserves and transfers output tokens

#### 4. Get Price
```solidity
function getPrice(address tokenA, address tokenB) 
    external view returns (uint256 price)
```

**Purpose**: Get current price of tokenA in terms of tokenB

**Parameters**:
- `tokenA`: Address of the token being priced
- `tokenB`: Address of the quote token

**Returns**:
- `price`: Price ratio with 18 decimal precision

**Calculation**: `price = (reserveB * 1e18) / reserveA`

#### 5. Calculate Output Amount
```solidity
function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
) external pure returns (uint256 amountOut)
```

**Purpose**: Calculate expected output tokens for a given input amount

**Parameters**:
- `amountIn`: Amount of input tokens
- `reserveIn`: Current reserve of input token
- `reserveOut`: Current reserve of output token

**Returns**:
- `amountOut`: Expected amount of output tokens

**Formula**: Uses constant product formula with 0.3% fee:
```
amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
```

## 📊 View Functions

### Get Reserves
```solidity
function getReserves() external view returns (uint256 _reserveEKA, uint256 _reserveEKB)
```
Returns current token reserves in the pool.

### Get Liquidity Shares
```solidity
function getLiquidityShares(address user) external view returns (uint256 shares)
```
Returns liquidity shares owned by a specific address.

### Get Total Liquidity
```solidity
function getTotalLiquidity() external view returns (uint256 total)
```
Returns total liquidity shares issued by the contract.

### Get Token Pair
```solidity
function getTokenPair() external view returns (address _tokenEKA, address _tokenEKB)
```
Returns the addresses of the supported token pair.

## 🔥 Events

### LiquidityAdded
```solidity
event LiquidityAdded(
    address indexed provider,
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
)
```
Emitted when liquidity is added to the pool.

### LiquidityRemoved
```solidity
event LiquidityRemoved(
    address indexed provider,
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
)
```
Emitted when liquidity is removed from the pool.

### TokensSwapped
```solidity
event TokensSwapped(
    address indexed user,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
)
```
Emitted when tokens are swapped.

## 🔐 Security Features

### Input Validation
- Non-zero address checks for all addresses
- Token pair validation (only EKA/EKB supported)
- Amount validation (positive values required)
- Deadline verification (prevents expired transactions)

### Slippage Protection
- Minimum amount parameters in liquidity operations
- Minimum output amount in swaps
- Prevents MEV attacks and sandwich trading

### Access Control
- Users can only remove their own liquidity
- No admin functions or upgradability (immutable)
- No pause mechanisms (always available)

### Economic Security
- Constant product formula prevents pool drainage
- Trading fees accumulate in reserves
- Liquidity share system prevents dilution attacks

## 🚀 Deployment

### Prerequisites
- Solidity ^0.8.0
- EKA token contract deployed
- EKB token contract deployed

### Constructor Parameters
```solidity
constructor(address _tokenEKA, address _tokenEKB)
```

### Deployment Steps
1. Deploy EKA and EKB token contracts
2. Deploy SimpleSwap with token addresses
3. Users approve tokens for the SimpleSwap contract
4. Add initial liquidity to bootstrap the pool

## 💡 Usage Examples

### Adding Liquidity
```solidity
// Approve tokens first
EKA.approve(simpleSwapAddress, amountEKA);
EKB.approve(simpleSwapAddress, amountEKB);

// Add liquidity
simpleSwap.addLiquidity(
    EKA_ADDRESS,
    EKB_ADDRESS,
    1000 * 10**18,  // 1000 EKA
    2000 * 10**18,  // 2000 EKB
    950 * 10**18,   // Min 950 EKA (5% slippage)
    1900 * 10**18,  // Min 1900 EKB (5% slippage)
    msg.sender,
    block.timestamp + 300  // 5 minute deadline
);
```

### Swapping Tokens
```solidity
// Approve input token
EKA.approve(simpleSwapAddress, swapAmount);

// Perform swap
address[] memory path = new address[](2);
path[0] = EKA_ADDRESS;  // Input token
path[1] = EKB_ADDRESS;  // Output token

simpleSwap.swapExactTokensForTokens(
    100 * 10**18,       // 100 EKA input
    180 * 10**18,       // Min 180 EKB output
    path,
    msg.sender,
    block.timestamp + 300
);
```

### Calculating Price
```solidity
uint256 priceEKAinEKB = simpleSwap.getPrice(EKA_ADDRESS, EKB_ADDRESS);
// Returns price with 18 decimal places
```

## 🧮 Mathematical Model

### Constant Product Formula
The AMM uses the constant product formula: **x × y = k**

Where:
- `x` = Reserve of token A
- `y` = Reserve of token B  
- `k` = Constant (product of reserves)

### Price Impact
Price impact increases with trade size relative to pool depth:
```
Price Impact = 1 - (reserveOut - amountOut) / reserveOut
```

### Liquidity Share Calculation
For first liquidity provision:
```
liquidity = sqrt(amountA * amountB)
```

For subsequent provisions:
```
liquidity = min(
    (amountA * totalLiquidity) / reserveA,
    (amountB * totalLiquidity) / reserveB
)
```

## ⚠️ Important Notes

### Limitations
- Only supports EKA-EKB token pair
- No multi-hop swapping capabilities
- Fixed 0.3% trading fee (not adjustable)
- No governance mechanism

### Risks
- **Impermanent Loss**: Liquidity providers face impermanent loss risk
- **Smart Contract Risk**: Code has not been audited
- **Token Risk**: Dependent on underlying token implementations
- **Slippage**: Large trades may experience significant price impact

### Best Practices
- Always set appropriate slippage tolerance
- Check token allowances before transactions
- Monitor gas costs for small trades
- Understand impermanent loss before providing liquidity

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a pull request

## 📞 Support

For questions or issues, please open a GitHub issue or contact the development team.

---

**Disclaimer**: This smart contract is provided as-is without warranties. Users should conduct their own security audits before deploying to mainnet.