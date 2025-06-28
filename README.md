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
1. **Liquidity Pool Architecture**:
   - The contract manages a single token pair (EKA, EKB) using direct imports from TokenA.sol and TokenB.sol contracts.
   - Pool structure uses custom liquidity share management:
     • `totalLiquidity`: Total amount of liquidity shares issued.
     • `liquidityShares`: Mapping of user addresses to their liquidity balance.
     • `tokenEKA` and `tokenEKB`: Immutable instances of the imported token contracts.

2. **Automated Market Maker (AMM)**:
   - Uses the constant product formula: `x * y = k`
   - Price discovery through reserve ratios with trading fee
   - Minimum locked liquidity (10,000 tokens) to prevent total pool drainage

3. **Direct Token Integration**:
   - Direct integration with TokenA and TokenB contracts without OpenZeppelin dependencies
   - Custom liquidity share system instead of ERC20 inheritance
   - Specific token transfer handling for each imported contract

4. **Events**:
   - `LiquidityProvided`: Emitted when a user adds liquidity to the pool.
   - `LiquidityWithdrawn`: Emitted when a user removes liquidity.
   - `TokenExchange`: Emitted when a swap is successfully executed.

## Functions:
**----------**

### 1. `addLiquidity(tokenA, tokenB, desiredAmountA, desiredAmountB, minimumAmountA, minimumAmountB, recipient, expirationTime)`
   - **Purpose**: Allows a user to provide liquidity to the EKA-EKB token pair.
   - **Process**: 
     • Validates token addresses match EKA/EKB pair using `_isValidTokenPair()`
     • Calculates optimal token proportions via `_calculateLiquidityAmounts()`
     • Uses direct token transfer methods from imported TokenA and TokenB contracts
     • Maintains current pool ratio
     • Ensures slippage protection with minimum amount requirements
     • Updates liquidity shares manually in the mapping system
   - **Returns**: `(actualAmountA, actualAmountB, liquidityTokens)` - actual amounts deposited and liquidity shares allocated

### 2. `removeLiquidity(tokenA, tokenB, liquidityAmount, minimumAmountA, minimumAmountB, recipient, expirationTime)`
   - **Purpose**: Allows a user to withdraw their proportional share of the liquidity pool.
   - **Process**:
     • Validates user input, token pair compatibility, and sufficient liquidity shares ownership
     • Calculates proportional withdrawal amounts based on current reserves and total liquidity
     • Burns user's liquidity shares from the mapping system
     • Enforces slippage protection and deadline validation
     • Uses direct token transfer methods to return underlying tokens to recipient
   - **Returns**: `(withdrawnAmountA, withdrawnAmountB)` - amounts of underlying tokens withdrawn

### 3. `swapExactTokensForTokens(inputAmount, minimumOutput, tradingPath, recipient, expirationTime)`
   - **Purpose**: Swaps an exact amount of input tokens for output tokens with fee application.
   - **Process**:
     • Validates trading path contains exactly two tokens (EKA/EKB)
     • Uses `_calculateSwapOutput()` for AMM calculations with trading fee
     • Determines correct token instance (TokenA or TokenB) for transfers
     • Ensures minimum output amount for slippage protection
     • Executes atomic token transfers using specific contract methods
   - **Returns**: `outputAmounts[]` - array containing [inputAmount, actualOutputAmount]

### 4. `getPrice(tokenA, tokenB)`
   - **Purpose**: Returns the current price of tokenA in terms of tokenB.
   - **Process**:
     • Validates tokens are part of the supported EKA-EKB pair
     • Uses `_getTokenBalance()` helper to retrieve current reserves
     • Calculates price ratio using current token reserves
     • Formula: `price = (reserveA * PRECISION) / reserveB`
   - **Returns**: `currentPrice` - price ratio

### 5. `getAmountOut(inputAmount, inputReserve, outputReserve)`
   - **Purpose**: Pure function to calculate expected output without fees for liquidity calculations.
   - **Process**:
     • Validates reserve values are positive (prevents division by zero)
     • Uses simple ratio formula: `expectedOutput = (inputAmount * outputReserve) / inputReserve`
     • Used internally for liquidity provision calculations
   - **Returns**: `expectedOutput` - calculated output amount without trading fees

## Internal Helper Functions:
**---------------------------**

### `_calculateLiquidityAmounts(tokenA, tokenB, desiredAmountA, desiredAmountB, minimumAmountA, minimumAmountB)`
   - **Purpose**: Internal function to calculate optimal liquidity amounts and prevent stack overflow.
   - **Process**: Uses `_getTokenBalance()` to retrieve reserves, determines optimal token ratios, handles empty pool case with square root calculation for first provision, calculates liquidity shares to allocate.
   - **Returns**: Tuple of actual amounts and liquidity shares.

### `_calculateSwapOutput(inputAmount, inputReserve, outputReserve)`
   - **Purpose**: Internal function to calculate swap output with trading fee applied.
   - **Process**: Applies fee factor to input amount before AMM calculation.
   - **Returns**: Output amount after fee deduction using constant product formula.

### `_isValidTokenPair(tokenA, tokenB)`
   - **Purpose**: Internal validation function to ensure token pair is supported EKA-EKB combination.
   - **Process**: Compares addresses with the imported TokenA and TokenB contract instances.
   - **Returns**: Boolean indicating if the token pair is valid.

### `_getTokenBalance(token)`
   - **Purpose**: Internal helper function to get balance for a specific token address.
   - **Process**: Determines which imported token contract to use (TokenA or TokenB) and calls the appropriate balanceOf method.
   - **Returns**: Current balance of the specified token in this contract.

### `_sqrt(x)`
   - **Purpose**: Internal function to calculate square root using Babylonian method.
   - **Process**: Used for calculating initial liquidity shares on first provision.
   - **Returns**: Square root of input value.

## View Functions:
**---------------**

### `getReserves()`
   - **Purpose**: Returns current reserves of both tokens in the pool.
   - **Process**: Calls balanceOf on both imported token contracts.
   - **Returns**: `(ekaReserve, ekbReserve)` - current token balances.

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

## Contract Architecture:
**----------------------**
- **Base Contract**: Standalone contract without ERC20 inheritance
- **Direct Imports**: TokenA and TokenB contracts imported directly from local files
- **Constants**: INITIAL_RESERVE (1), PRECISION (1e18), MINIMUM_LOCKED_LIQUIDITY (10,000), FEE_FACTOR (997), FEE_DENOMINATOR (1000)
- **Immutable Instances**: tokenEKA (TokenA instance), tokenEKB (TokenB instance)
- **Liquidity Management**: Custom mapping-based system for tracking user shares
- **Core Components**: AMM functions, internal helper functions, view functions for pool state queries