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
   - The contract manages a single token pair (EKA, EKB) using separate TokenA.sol and TokenB.sol contracts.
   - Pool structure inherits from ERC20 for native LP token functionality:
     • `totalSupply()`: Total amount of liquidity tokens issued.
     • `balanceOf(user)`: User's liquidity token balance.
     • `ekaToken` and `ekbToken`: Immutable addresses of the supported token contracts.

2. **Automated Market Maker (AMM)**:
   - Uses the constant product formula: `x * y = k`
   - Price discovery through reserve ratios with trading fee
   - Minimum locked liquidity (10,000 tokens) to prevent total pool drainage

3. **Stack Optimization**:
   - Internal helper function (`_calculateLiquidityAmounts`) prevents "stack too deep" compilation errors
   - Modular design improves code readability and gas efficiency

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
     • Maintains current pool ratio
     • Ensures slippage protection with minimum amount requirements
     • Transfers tokens from user and mints LP tokens to recipient
   - **Returns**: `(actualAmountA, actualAmountB, liquidityTokens)` - actual amounts deposited and LP tokens minted

### 2. `removeLiquidity(tokenA, tokenB, liquidityAmount, minimumAmountA, minimumAmountB, recipient, expirationTime)`
   - **Purpose**: Allows a user to withdraw their proportional share of the liquidity pool.
   - **Process**:
     • Validates user input and token pair compatibility
     • Calculates proportional withdrawal amounts based on current reserves and total supply
     • Burns user's LP tokens from their balance
     • Enforces slippage protection and deadline validation
     • Returns underlying tokens to specified recipient
   - **Returns**: `(withdrawnAmountA, withdrawnAmountB)` - amounts of underlying tokens withdrawn

### 3. `swapExactTokensForTokens(inputAmount, minimumOutput, tradingPath, recipient, expirationTime)`
   - **Purpose**: Swaps an exact amount of input tokens for output tokens with fee application.
   - **Process**:
     • Validates trading path contains exactly two tokens (EKA/EKB)
     • Uses `_calculateSwapOutput()` for AMM calculations with trading fee
     • Ensures minimum output amount for slippage protection
     • Executes atomic token transfers (input from user, output to recipient)
   - **Returns**: `outputAmounts[]` - array containing [inputAmount, actualOutputAmount]

### 4. `getPrice(tokenA, tokenB)`
   - **Purpose**: Returns the current price of tokenA in terms of tokenB.
   - **Process**:
     • Validates tokens are part of the supported EKA-EKB pair
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
   - **Process**: Determines optimal token ratios, handles empty pool case, calculates LP tokens to mint.
   - **Returns**: Tuple of actual amounts and liquidity tokens.

### `_calculateSwapOutput(inputAmount, inputReserve, outputReserve)`
   - **Purpose**: Internal function to calculate swap output with trading fee applied.
   - **Process**: Applies fee factor to input amount before AMM calculation.
   - **Returns**: Output amount after fee deduction using constant product formula.

### `_isValidTokenPair(tokenA, tokenB)`
   - **Purpose**: Internal validation function to ensure token pair is supported EKA-EKB combination.
   - **Returns**: Boolean indicating if the token pair is valid.

## Contract Architecture:
**----------------------**
- **Base Contract**: Inherits from ERC20 for native LP token functionality
- **Constants**: INITIAL_RESERVE (1), PRECISION (1e18), MINIMUM_LOCKED_LIQUIDITY (10,000), FEE_FACTOR (997), FEE_DENOMINATOR (1000)
- **Immutable Variables**: ekaToken address (TokenA.sol deployment), ekbToken address (TokenB.sol deployment)
- **Core Components**: AMM functions, internal helper functions, view functions for pool state queries