# SimpleSwap
TPETHSimpleSwap
# 🌀 SimpleSwap - Detailed Explanation

## Overview:
**----------**
SimpleSwap is a decentralized exchange (DEX) smart contract implemented in Solidity. Inspired by the core mechanics of Uniswap, it allows users to:
1. Add liquidity to a pool of two ERC-20 tokens (EKA and EKB).
2. Remove liquidity from an existing pool.
3. Swap tokens between the EKA-EKB pair with an automatic pricing mechanism.
4. Query token prices and expected swap outputs.

## Core Concepts:
**--------------**
1. **Liquidity Pool Architecture**:
   - The contract manages a single token pair (EKA, EKB) using direct imports from TokenA.sol and TokenB.sol contracts.
   - Pool structure uses custom liquidity share management:
     • `totalLiquidity`: Total amount of liquidity shares issued.
     • `liquidityShares`: Mapping of user addresses to their liquidity balance.
     • `tokenEKA` and `tokenEKB`: Immutable instances of the imported token contracts.

2. **Automated Market Maker (AMM)**:
   - Uses the constant product formula: `x * y = k`
   - Price discovery through reserve ratios without trading fees
   - Minimum locked liquidity (1,000 tokens) to prevent total pool drainage

3. **Direct Token Integration**:
   - Direct integration with TokenA and TokenB contracts without OpenZeppelin dependencies
   - Custom liquidity share system instead of ERC20 inheritance
   - Specific token transfer handling for each imported contract

4. **Events**:
   - `LiquidityAdded`: Emitted when a user adds liquidity to the pool.
   - `LiquidityRemoved`: Emitted when a user removes liquidity.
   - `TokensSwapped`: Emitted when a swap is successfully executed.

## Functions:
**----------**

### 1. `addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline)`
   - **Purpose**: Allows a user to provide liquidity to the EKA-EKB token pair.
   - **Process**: 
     • Validates token addresses match EKA/EKB pair using `_isValidTokenPair()`
     • Calculates optimal token proportions based on current pool reserves
     • For empty pools, uses desired amounts directly
     • For existing pools, maintains current ratio to prevent arbitrage
     • Ensures slippage protection with minimum amount requirements
     • Updates liquidity shares manually in the mapping system
   - **Returns**: `(amountA, amountB, liquidity)` - actual amounts deposited and liquidity shares allocated

### 2. `removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline)`
   - **Purpose**: Allows a user to withdraw their proportional share of the liquidity pool.
   - **Process**:
     • Validates user input, token pair compatibility, and sufficient liquidity shares ownership
     • Calculates proportional withdrawal amounts based on current reserves and total liquidity
     • Burns user's liquidity shares from the mapping system
     • Enforces slippage protection and deadline validation
     • Uses direct token transfer methods to return underlying tokens to recipient
   - **Returns**: `(amountA, amountB)` - amounts of underlying tokens withdrawn

### 3. `swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline)`
   - **Purpose**: Swaps an exact amount of input tokens for output tokens using constant product formula.
   - **Process**:
     • Validates trading path contains exactly two tokens (EKA/EKB)
     • Uses `getAmountOut()` for AMM calculations without any fees
     • Determines correct token instance (TokenA or TokenB) for transfers
     • Ensures minimum output amount for slippage protection
     • Executes atomic token transfers using specific contract methods
   - **Returns**: `amounts[]` - array containing [inputAmount, actualOutputAmount]

### 4. `getPrice(tokenA, tokenB)`
   - **Purpose**: Returns the current price of tokenA in terms of tokenB.
   - **Process**:
     • Validates tokens are part of the supported EKA-EKB pair
     • Uses `_getTokenBalance()` helper to retrieve current reserves
     • Calculates price ratio using current token reserves
     • Formula: `price = (reserveB * 1e18) / reserveA`
   - **Returns**: `price` - price ratio scaled by 1e18 for precision

### 5. `getAmountOut(amountIn, reserveIn, reserveOut)`
   - **Purpose**: Pure function to calculate expected output for swaps and liquidity calculations.
   - **Process**:
     • Validates input amount and reserve values are positive
     • Uses constant product formula: `(amountIn * reserveOut) / (reserveIn + amountIn)`
     • No fees applied - pure mathematical calculation
     • Used by both swap and liquidity functions
   - **Returns**: `amountOut` - calculated output amount without any fees

## Internal Helper Functions:
**---------------------------**

### `_isValidTokenPair(tokenA, tokenB)`
   - **Purpose**: Internal validation function to ensure token pair is supported EKA-EKB combination.
   - **Process**: Compares addresses with the imported TokenA and TokenB contract instances.
   - **Returns**: Boolean indicating if the token pair is valid.

### `_getTokenBalance(token)`
   - **Purpose**: Internal helper function to get balance for a specific token address.
   - **Process**: Determines which imported token contract to use (TokenA or TokenB) and calls the appropriate balanceOf method.
   - **Returns**: Current balance of the specified token in this contract.

### `_transferTokensFrom(token, from, to, amount)`
   - **Purpose**: Internal function to handle transferFrom operations for both token types.
   - **Process**: Determines token type and calls the appropriate transferFrom method.
   - **Returns**: Boolean indicating transfer success.

### `_transferTokens(token, to, amount)`
   - **Purpose**: Internal function to handle transfer operations from contract to user.
   - **Process**: Determines token type and calls the appropriate transfer method.
   - **Returns**: Boolean indicating transfer success.

### `_sqrt(x)`
   - **Purpose**: Internal function to calculate square root using Babylonian method.
   - **Process**: Used for calculating initial liquidity shares on first provision.
   - **Returns**: Square root of input value.

## View Functions:
**---------------**

### `getReserves()`
   - **Purpose**: Returns current reserves of both tokens in the pool.
   - **Process**: Calls balanceOf on both imported token contracts.
   - **Returns**: `(reserveEKA, reserveEKB)` - current token balances.

### `getSupportedTokens()`
   - **Purpose**: Returns the addresses of supported token contracts.
   - **Process**: Returns addresses of the imported TokenA and TokenB instances.
   - **Returns**: `(tokenA, tokenB)` - addresses of EKA and EKB contracts.

### `getLiquidityShares(user)`
   - **Purpose**: Returns liquidity shares owned by a specific user.
   - **Process**: Queries the liquidityShares mapping.
   - **Returns**: `shares` - amount of liquidity shares owned by the user.

### `getTotalLiquidity()`
   - **Purpose**: Returns total liquidity shares in the pool.
   - **Process**: Returns the totalLiquidity state variable.
   - **Returns**: `total` - total amount of liquidity shares issued.

## Mathematical Model:
**-------------------**
- **Constant Product Formula**: `(x + Δx) * (y - Δy) = x * y` where x and y are token reserves
- **Price Calculation**: `price = (reserveB * 1e18) / reserveA` (scaled for precision)
- **Liquidity Shares** (first provision): `sqrt(amountA * amountB)` using geometric mean
- **Liquidity Shares** (subsequent): `min(liquidityA, liquidityB)` where `liquidityA = (amountA * totalLiquidity) / reserveA`
- **Swap Output**: `amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)` - pure constant product without fees
- **No Trading Fees**: All calculations use pure mathematical formulas without fee deductions

## Contract Architecture:
**----------------------**
- **Base Contract**: Standalone contract without ERC20 inheritance
- **Direct Imports**: TokenA and TokenB contracts imported directly from local files
- **Constants**: INITIAL_RESERVE (1), MINIMUM_LOCKED_LIQUIDITY (1,000)
- **Immutable Instances**: tokenEKA (TokenA instance), tokenEKB (TokenB instance)
- **Liquidity Management**: Custom mapping-based system for tracking user shares without ERC20 overhead
- **Core Components**: Five main AMM functions, internal helper functions, view functions for pool state queries
- **No Fee Structure**: Pure AMM implementation without trading fees or additional costs