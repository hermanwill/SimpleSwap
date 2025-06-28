# SimpleSwap
TPETHSimpleSwap

## Overview:
**----------**
SimpleSwap is a decentralized exchange (DEX) smart contract implemented in Solidity. Inspired by the core mechanics of Uniswap, it allows users to:
1. Add liquidity to a pool of two ERC-20 tokens (EKA and EKB).
2. Remove liquidity from an existing pool.
3. Swap tokens between the EKA-EKB pair with an automatic pricing mechanism.
4. Query token prices and expected swap outputs.

## Core Concepts:
**--------------**
1. **Liquidity Pool**:
   - The contract manages a single token pair (EKA, EKB) with dedicated storage variables.
   - Pool structure contains:
     • `totalLiquidity`: Total amount of liquidity shares issued.
     • `liquidityShares`: Mapping of user addresses to their liquidity balance.
     • `reserveEKA` and `reserveEKB`: Current token reserves in the pool.

2. **Automated Market Maker (AMM)**:
   - Uses the constant product formula: `x * y = k`
   - Price discovery through reserve ratios
   - 0.3% trading fee on all swaps

3. **Events**:
   - `LiquidityAdded`: Emitted when a user provides liquidity to the pool.
   - `LiquidityRemoved`: Emitted when a user withdraws liquidity.
   - `TokensSwapped`: Emitted when a swap is successfully executed.

## Functions:
**----------**

### 1. `addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline)`
   - **Purpose**: Allows a user to provide liquidity to the EKA-EKB token pair.
   - **Process**: 
     • Validates token addresses match EKA/EKB pair
     • Calculates optimal token proportions maintaining pool ratio
     • Ensures slippage protection with minimum amounts
     • Transfers tokens from user to contract
     • Mints and assigns liquidity shares to the `to` address
   - **Returns**: `(amountA, amountB, liquidity)` - actual amounts added and shares minted

### 2. `removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline)`
   - **Purpose**: Allows a user to withdraw their share of the liquidity pool.
   - **Process**:
     • Validates user owns sufficient liquidity shares
     • Calculates proportional token amounts based on pool reserves
     • Burns the user's liquidity shares
     • Enforces slippage protection and deadline validation
     • Returns tokenA and tokenB to the `to` address
   - **Returns**: `(amountA, amountB)` - amounts of tokens withdrawn

### 3. `swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline)`
   - **Purpose**: Swaps an exact amount of input tokens for output tokens.
   - **Process**:
     • Validates path contains exactly two tokens (EKA/EKB)
     • Uses constant product formula for price calculation
     • Applies 0.3% trading fee
     • Ensures minimum output amount for slippage protection
     • Transfers input tokens from user and output tokens to `to` address
   - **Returns**: `amounts[]` - array containing input and output amounts

### 4. `getPrice(tokenA, tokenB)`
   - **Purpose**: Returns the current price of tokenA denominated in tokenB.
   - **Process**:
     • Validates tokens are part of the EKA-EKB pair
     • Calculates price ratio using current reserves
   - **Returns**: `price` - scaled by 1e18 to support decimals

### 5. `getAmountOut(amountIn, reserveIn, reserveOut)`
   - **Purpose**: Pure function to calculate the output amount of a swap based on constant product formula.
   - **Process**:
     • Applies 0.3% fee (997/1000 of input amount)
     • Uses formula: `amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)`
     • Ensures input and reserve values are valid
   - **Returns**: `amountOut` - expected output amount

## Mathematical Model:
**-------------------**
- **Constant Product Formula**: `x * y = k` where x and y are token reserves
- **Price Calculation**: `price = reserveB / reserveA`
- **Liquidity Shares** (first provision): `sqrt(amountA * amountB)`
- **Liquidity Shares** (subsequent): `(amountA * totalLiquidity) / reserveA`
- **Trading Fee**: 0.3% applied to input amount before swap calculation

## Error Handling:
**----------------**
The contract implements comprehensive validation with descriptive error messages:
- `"Transaction expired"` — Operation attempted after deadline
- `"Invalid token pair"` — Tokens are not EKA/EKB or are identical
- `"Amounts must be greater than zero"` — Input amounts are zero or invalid
- `"Insufficient liquidity shares"` — User lacks required liquidity balance
- `"Insufficient output amount"` — Swap output below minimum threshold
- `"Insufficient liquidity"` — Pool reserves too low for operation
- `"Invalid path length"` — Swap path doesn't contain exactly 2 tokens
- `"Invalid recipient address"` — Destination address is zero address

## Security Features:
**------------------**
- **Input Validation**: Comprehensive checks for all parameters including addresses, amounts, and deadlines
- **Slippage Protection**: Minimum amount parameters prevent MEV attacks and excessive slippage
- **Deadline Validation**: Time-based protection using `ensure(deadline)` modifier
- **Reserve Management**: Proper balance tracking prevents pool drainage
- **Access Control**: Users can only withdraw their own liquidity shares
- **Immutable Design**: No admin functions or upgrade mechanisms for maximum decentralization

```

## Deployment Requirements:
**-------------------------**
- **Solidity Version**: ^0.8.0
- **Dependencies**: EKA and EKB token contracts must be deployed first
- **Constructor Parameters**: `(address _tokenEKA, address _tokenEKB)`
- **Gas Optimization**: Uses efficient algorithms and minimal storage

## Limitations:
**-------------**
- Supports only EKA-EKB token pair (no multi-pair functionality)
- Fixed 0.3% trading fee (not configurable)
- No governance mechanism or parameter adjustment
- Single-hop swaps only (no routing through multiple pairs)

## Risk Considerations:
**--------------------**
- **Impermanent Loss**: Liquidity providers face potential impermanent loss
- **Smart Contract Risk**: Code should be audited before mainnet deployment
- **Slippage Risk**: Large trades may experience significant price impact
- **Token Risk**: Dependent on proper implementation of underlying ERC-20 tokens