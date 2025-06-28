// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TokenA} from "./TokenA.sol";
import {TokenB} from "./TokenB.sol";

/**
 * @title SimpleSwap
 * @dev Decentralized exchange contract for swapping between TokenA (EKA) and TokenB (EKB)
 * @dev Implements automated market maker functionality with liquidity provision
 */
contract SimpleSwap {

    /// @notice Default reserve value used when pool is empty to prevent division by zero
    /// @dev Set to 1 to allow initial calculations without special handling
    uint256 private constant INITIAL_RESERVE = 1;

    /// @notice Precision constant for 18-decimal calculations
    uint256 private constant PRECISION = 1e18;

    /// @notice Minimum liquidity tokens locked permanently on first provision
    /// @dev Prevents liquidity drain attacks and maintains price stability
    uint256 private constant MINIMUM_LOCKED_LIQUIDITY = 10_000;

    /// @notice Fee percentage applied to swaps
    uint256 private constant FEE_FACTOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;

    /// @notice TokenA (EKA) contract instance
    TokenA public immutable tokenEKA;
    
    /// @notice TokenB (EKB) contract instance
    TokenB public immutable tokenEKB;

    /// @notice Total liquidity shares issued
    uint256 public totalLiquidity;
    
    /// @notice Mapping of user addresses to their liquidity shares
    mapping(address => uint256) public liquidityShares;

    /// @notice Emitted when liquidity is added to the pool
    event LiquidityProvided(address indexed provider, uint256 ekaAmount, uint256 ekbAmount, uint256 liquidityMinted);
    
    /// @notice Emitted when liquidity is removed from the pool
    event LiquidityWithdrawn(address indexed provider, uint256 ekaAmount, uint256 ekbAmount, uint256 liquidityBurned);
    
    /// @notice Emitted when tokens are swapped
    event TokenExchange(address indexed trader, address indexed recipient, uint256 inputAmount, uint256 outputAmount);

    /**
     * @dev Constructor initializes the contract with TokenA and TokenB instances
     * @param _tokenEKA Address of the deployed TokenA (EKA) contract
     * @param _tokenEKB Address of the deployed TokenB (EKB) contract
     */
    constructor(address _tokenEKA, address _tokenEKB) {
        require(_tokenEKA != address(0) && _tokenEKB != address(0), "InvalidTokenAddress");
        require(_tokenEKA != _tokenEKB, "IdenticalTokens");
        
        tokenEKA = TokenA(_tokenEKA);
        tokenEKB = TokenB(_tokenEKB);
        
        // Initialize with minimum liquidity to prevent total drain
        totalLiquidity = MINIMUM_LOCKED_LIQUIDITY;
    }

    /// @notice Validates that function is called before specified deadline
    /// @param expirationTime Unix timestamp after which the transaction becomes invalid
    modifier withinDeadline(uint256 expirationTime) {
        require(expirationTime >= block.timestamp, "TransactionExpired");
        _;
    }

    /**
     * @notice Adds liquidity to the EKA/EKB trading pair
     * @dev Calculates optimal token amounts based on current pool ratios
     * @param tokenA Address of first token (must be EKA or EKB)
     * @param tokenB Address of second token (must be EKA or EKB)
     * @param desiredAmountA Maximum amount of tokenA willing to deposit
     * @param desiredAmountB Maximum amount of tokenB willing to deposit
     * @param minimumAmountA Minimum amount of tokenA to accept (slippage protection)
     * @param minimumAmountB Minimum amount of tokenB to accept (slippage protection)
     * @param recipient Address that will receive the liquidity tokens
     * @param expirationTime Transaction deadline timestamp
     * @return actualAmountA Actual amount of tokenA deposited
     * @return actualAmountB Actual amount of tokenB deposited
     * @return liquidityTokens Amount of LP tokens minted to recipient
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 desiredAmountA,
        uint256 desiredAmountB,
        uint256 minimumAmountA,
        uint256 minimumAmountB,
        address recipient,
        uint256 expirationTime
    ) external withinDeadline(expirationTime) returns (uint256 actualAmountA, uint256 actualAmountB, uint256 liquidityTokens) {
        
        // Validate inputs
        require(_isValidTokenPair(tokenA, tokenB), "UnsupportedTokenPair");
        require(recipient != address(0), "InvalidRecipient");
        
        // Calculate optimal amounts and liquidity
        (actualAmountA, actualAmountB, liquidityTokens) = _calculateLiquidityAmounts(
            tokenA, 
            tokenB, 
            desiredAmountA, 
            desiredAmountB, 
            minimumAmountA, 
            minimumAmountB
        );

        // Execute transfers and mint liquidity shares
        if (tokenA == address(tokenEKA)) {
            require(tokenEKA.transferFrom(msg.sender, address(this), actualAmountA), "TokenATransferFailed");
            require(tokenEKB.transferFrom(msg.sender, address(this), actualAmountB), "TokenBTransferFailed");
        } else {
            require(tokenEKB.transferFrom(msg.sender, address(this), actualAmountA), "TokenATransferFailed");
            require(tokenEKA.transferFrom(msg.sender, address(this), actualAmountB), "TokenBTransferFailed");
        }
        
        totalLiquidity += liquidityTokens;
        liquidityShares[recipient] += liquidityTokens;

        emit LiquidityProvided(msg.sender, actualAmountA, actualAmountB, liquidityTokens);
    }

    /**
     * @dev Internal function to calculate optimal liquidity amounts
     * @param tokenA Address of first token
     * @param tokenB Address of second token
     * @param desiredAmountA Desired amount of tokenA
     * @param desiredAmountB Desired amount of tokenB
     * @param minimumAmountA Minimum amount of tokenA
     * @param minimumAmountB Minimum amount of tokenB
     * @return actualAmountA Calculated actual amount A
     * @return actualAmountB Calculated actual amount B
     * @return liquidityTokens Calculated liquidity tokens to mint
     */
    function _calculateLiquidityAmounts(
        address tokenA,
        address tokenB,
        uint256 desiredAmountA,
        uint256 desiredAmountB,
        uint256 minimumAmountA,
        uint256 minimumAmountB
    ) internal view returns (uint256 actualAmountA, uint256 actualAmountB, uint256 liquidityTokens) {
        
        // Get current reserves
        uint256 reserveA = _getTokenBalance(tokenA);
        uint256 reserveB = _getTokenBalance(tokenB);
        
        // Handle empty pool case
        if (reserveA == 0 && reserveB == 0) {
            reserveA = INITIAL_RESERVE;
            reserveB = INITIAL_RESERVE;
        }

        // Calculate optimal amounts
        uint256 optimalA = getAmountOut(desiredAmountB, reserveB, reserveA);
        if (optimalA <= desiredAmountA) {
            require(optimalA >= minimumAmountA, "InsufficientTokenAAmount");
            actualAmountA = optimalA;
            actualAmountB = desiredAmountB;
        } else {
            uint256 optimalB = getAmountOut(desiredAmountA, reserveA, reserveB);
            require(optimalB >= minimumAmountB, "InsufficientTokenBAmount");
            actualAmountA = desiredAmountA;
            actualAmountB = optimalB;
        }
        
        // Calculate liquidity tokens
        if (totalLiquidity == MINIMUM_LOCKED_LIQUIDITY) {
            // First liquidity provision
            liquidityTokens = _sqrt(actualAmountA * actualAmountB);
        } else {
            uint256 liquidityA = (actualAmountA * totalLiquidity) / reserveA;
            uint256 liquidityB = (actualAmountB * totalLiquidity) / reserveB;
            liquidityTokens = liquidityA < liquidityB ? liquidityA : liquidityB;
        }
    }

    /**
     * @notice Removes liquidity from the pool by burning LP tokens
     * @param tokenA Address of first token (must be EKA or EKB)
     * @param tokenB Address of second token (must be EKA or EKB)
     * @param liquidityAmount Amount of LP tokens to burn
     * @param minimumAmountA Minimum amount of tokenA to receive
     * @param minimumAmountB Minimum amount of tokenB to receive
     * @param recipient Address that will receive the underlying tokens
     * @param expirationTime Transaction deadline timestamp
     * @return withdrawnAmountA Amount of tokenA returned to recipient
     * @return withdrawnAmountB Amount of tokenB returned to recipient
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidityAmount,
        uint256 minimumAmountA,
        uint256 minimumAmountB,
        address recipient,
        uint256 expirationTime
    ) external withinDeadline(expirationTime) returns (uint256 withdrawnAmountA, uint256 withdrawnAmountB) {
    
        // Validate inputs
        require(_isValidTokenPair(tokenA, tokenB), "UnsupportedTokenPair");
        require(recipient != address(0), "InvalidRecipient");
        require(liquidityAmount > 0, "ZeroLiquidityAmount");
        require(liquidityShares[msg.sender] >= liquidityAmount, "InsufficientLiquidityShares");
        
        // Get current reserves
        uint256 currentReserveA = _getTokenBalance(tokenA);
        uint256 currentReserveB = _getTokenBalance(tokenB);
        
        // Calculate proportional token amounts to return
        withdrawnAmountA = (liquidityAmount * currentReserveA) / totalLiquidity;
        withdrawnAmountB = (liquidityAmount * currentReserveB) / totalLiquidity;
        
        // Validate minimum amounts for slippage protection
        require(withdrawnAmountA >= minimumAmountA, "InsufficientTokenAAmount");
        require(withdrawnAmountB >= minimumAmountB, "InsufficientTokenBAmount");

        // Burn liquidity tokens first
        liquidityShares[msg.sender] -= liquidityAmount;
        totalLiquidity -= liquidityAmount;

        // Transfer tokens to recipient
        if (tokenA == address(tokenEKA)) {
            require(tokenEKA.transfer(recipient, withdrawnAmountA), "TokenATransferFailed");
            require(tokenEKB.transfer(recipient, withdrawnAmountB), "TokenBTransferFailed");
        } else {
            require(tokenEKB.transfer(recipient, withdrawnAmountA), "TokenATransferFailed");
            require(tokenEKA.transfer(recipient, withdrawnAmountB), "TokenBTransferFailed");
        }

        emit LiquidityWithdrawn(msg.sender, withdrawnAmountA, withdrawnAmountB, liquidityAmount);
    }

    /**
     * @notice Swaps exact input tokens for output tokens
     * @param inputAmount Exact amount of input tokens to trade
     * @param minimumOutput Minimum acceptable amount of output tokens
     * @param tradingPath Array containing [inputToken, outputToken] addresses
     * @param recipient Address that will receive the output tokens
     * @param expirationTime Transaction deadline timestamp
     * @return outputAmounts Array containing [inputAmount, actualOutputAmount]
     */
    function swapExactTokensForTokens(
        uint256 inputAmount,
        uint256 minimumOutput,
        address[] calldata tradingPath,
        address recipient,
        uint256 expirationTime
    ) external withinDeadline(expirationTime) returns (uint256[] memory outputAmounts) {
        
        require(tradingPath.length == 2, "InvalidTradingPath");
        require(recipient != address(0), "InvalidRecipient");
        require(_isValidTokenPair(tradingPath[0], tradingPath[1]), "UnsupportedTokenPair");

        // Get current reserves for input and output tokens
        uint256 inputReserve = _getTokenBalance(tradingPath[0]);
        uint256 outputReserve = _getTokenBalance(tradingPath[1]);

        // Calculate output amount using AMM formula with fee
        uint256 actualOutput = _calculateSwapOutput(inputAmount, inputReserve, outputReserve);
        require(actualOutput >= minimumOutput, "InsufficientOutputAmount");

        // Execute token transfers
        if (tradingPath[0] == address(tokenEKA)) {
            require(tokenEKA.transferFrom(msg.sender, address(this), inputAmount), "InputTransferFailed");
            require(tokenEKB.transfer(recipient, actualOutput), "OutputTransferFailed");
        } else {
            require(tokenEKB.transferFrom(msg.sender, address(this), inputAmount), "InputTransferFailed");
            require(tokenEKA.transfer(recipient, actualOutput), "OutputTransferFailed");
        }
        
        // Prepare return array
        outputAmounts = new uint256[](2);
        outputAmounts[0] = inputAmount;
        outputAmounts[1] = actualOutput;
        
        emit TokenExchange(msg.sender, recipient, inputAmount, actualOutput);
    }

    /**
     * @notice Returns current price of tokenA in terms of tokenB
     * @param tokenA Base token address
     * @param tokenB Quote token address  
     * @return currentPrice Price ratio
     */
    function getPrice(address tokenA, address tokenB) external view returns (uint256 currentPrice) {
        require(_isValidTokenPair(tokenA, tokenB), "UnsupportedTokenPair");
        
        uint256 reserveA = _getTokenBalance(tokenA);
        uint256 reserveB = _getTokenBalance(tokenB);
        require(reserveA > 0 && reserveB > 0, "InsufficientReserves");
        
        return (reserveA * PRECISION) / reserveB;
    }

    /**
     * @notice Calculates expected output amount for a given input without fees
     * @param inputAmount Amount of input tokens
     * @param inputReserve Current reserve of input token
     * @param outputReserve Current reserve of output token
     * @return expectedOutput Calculated output amount
     */
    function getAmountOut(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) 
        public pure returns (uint256 expectedOutput) {
        require(inputReserve > 0 && outputReserve > 0, "InsufficientReserves");
        return expectedOutput = (inputAmount * outputReserve) / inputReserve;
    }

    /**
     * @dev Internal function to calculate swap output with trading fee applied
     * @param inputAmount Amount of tokens being swapped in
     * @param inputReserve Current reserve of input token  
     * @param outputReserve Current reserve of output token
     * @return outputAmount Amount of output tokens after fee
     */
    function _calculateSwapOutput(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) 
        internal pure returns (uint256 outputAmount) {
        require(inputReserve > 0 && outputReserve > 0, "InsufficientReserves");
        
        uint256 inputWithFee = inputAmount * FEE_FACTOR;
        uint256 numerator = inputWithFee * outputReserve;
        uint256 denominator = (inputReserve * FEE_DENOMINATOR) + inputWithFee;
        
        return numerator / denominator;
    }

    /**
     * @dev Internal function to validate if token pair is supported (EKA-EKB)
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return isValid True if tokens form a valid EKA-EKB pair
     */
    function _isValidTokenPair(address tokenA, address tokenB) internal view returns (bool isValid) {
        return (tokenA == address(tokenEKA) && tokenB == address(tokenEKB)) || 
               (tokenA == address(tokenEKB) && tokenB == address(tokenEKA));
    }

    /**
     * @dev Internal function to get token balance for a given token address
     * @param token Token address to check balance for
     * @return balance Current balance of the token in this contract
     */
    function _getTokenBalance(address token) internal view returns (uint256 balance) {
        if (token == address(tokenEKA)) {
            return tokenEKA.balanceOf(address(this));
        } else if (token == address(tokenEKB)) {
            return tokenEKB.balanceOf(address(this));
        } else {
            revert("UnsupportedToken");
        }
    }

    /**
     * @dev Internal function to calculate square root using Babylonian method
     * @param x Input value
     * @return y Square root of x
     */
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @notice Returns current reserves of both tokens in the pool
     * @return ekaReserve Current EKA token balance in contract
     * @return ekbReserve Current EKB token balance in contract
     */
    function getReserves() external view returns (uint256 ekaReserve, uint256 ekbReserve) {
        ekaReserve = tokenEKA.balanceOf(address(this));
        ekbReserve = tokenEKB.balanceOf(address(this));
    }

    /**
     * @notice Returns the token addresses supported by this DEX
     * @return tokenA Address of EKA token contract
     * @return tokenB Address of EKB token contract
     */
    function getSupportedTokens() external view returns (address tokenA, address tokenB) {
        tokenA = address(tokenEKA);
        tokenB = address(tokenEKB);
    }

    /**
     * @notice Returns liquidity shares owned by a user
     * @param user Address to check liquidity shares for
     * @return shares Amount of liquidity shares owned by the user
     */
    function getLiquidityShares(address user) external view returns (uint256 shares) {
        return liquidityShares[user];
    }

    /**
     * @notice Returns total liquidity in the pool
     * @return total Total amount of liquidity shares issued
     */
    function getTotalLiquidity() external view returns (uint256 total) {
        return totalLiquidity;
    }
}