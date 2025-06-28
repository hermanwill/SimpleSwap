// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SimpleSwap
 * @dev Decentralized exchange contract for swapping between TokenA (EKA) and TokenB (EKB)
 * @dev Implements automated market maker functionality with liquidity provision
 */
contract SimpleSwap is ERC20 {

    /// @notice Default reserve value used when pool is empty to prevent division by zero
    /// @dev Set to 1 to allow initial calculations without special handling
    uint256 private constant INITIAL_RESERVE = 1;

    /// @notice Precision constant for 18-decimal calculations (1 × 10¹⁸)
    uint256 private constant PRECISION = 1e18;

    /// @notice Minimum liquidity tokens locked permanently on first provision
    /// @dev Prevents liquidity drain attacks and maintains price stability
    uint256 private constant MINIMUM_LOCKED_LIQUIDITY = 10_000;

    /// @notice Fee percentage applied to swaps (0.3% = 997/1000)
    uint256 private constant FEE_FACTOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;

    /// @notice Address of TokenA (EKA) contract
    address public immutable ekaToken;
    
    /// @notice Address of TokenB (EKB) contract  
    address public immutable ekbToken;

    /// @notice Emitted when liquidity is added to the pool
    event LiquidityProvided(address indexed provider, uint256 ekaAmount, uint256 ekbAmount, uint256 liquidityMinted);
    
    /// @notice Emitted when liquidity is removed from the pool
    event LiquidityWithdrawn(address indexed provider, uint256 ekaAmount, uint256 ekbAmount, uint256 liquidityBurned);
    
    /// @notice Emitted when tokens are swapped
    event TokenExchange(address indexed trader, address indexed recipient, uint256 inputAmount, uint256 outputAmount);

    /**
     * @dev Constructor initializes the contract with TokenA and TokenB addresses
     * @param _ekaToken Address of the deployed TokenA (EKA) contract
     * @param _ekbToken Address of the deployed TokenB (EKB) contract
     */
    constructor(address _ekaToken, address _ekbToken) ERC20("EKA-EKB Liquidity", "EKA-EKB-LP") {
        require(_ekaToken != address(0) && _ekbToken != address(0), "InvalidTokenAddress");
        require(_ekaToken != _ekbToken, "IdenticalTokens");
        
        ekaToken = _ekaToken;
        ekbToken = _ekbToken;
        
        // Mint minimum liquidity to contract to prevent total drain
        _mint(address(this), MINIMUM_LOCKED_LIQUIDITY);
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

        // Execute transfers and mint
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), actualAmountA), "TokenATransferFailed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), actualAmountB), "TokenBTransferFailed");
        _mint(recipient, liquidityTokens);

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
        uint256 reserveA = IERC20(tokenA).balanceOf(address(this));
        uint256 reserveB = IERC20(tokenB).balanceOf(address(this));
        
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
        uint256 supply = totalSupply();
        uint256 liquidityA = (actualAmountA * supply) / reserveA;
        uint256 liquidityB = (actualAmountB * supply) / reserveB;
        liquidityTokens = liquidityA < liquidityB ? liquidityA : liquidityB;
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
        
        // Get current reserves and total supply
        uint256 currentReserveA = IERC20(tokenA).balanceOf(address(this));
        uint256 currentReserveB = IERC20(tokenB).balanceOf(address(this));
        uint256 currentTotalSupply = totalSupply();
        
        // Calculate proportional token amounts to return
        withdrawnAmountA = (liquidityAmount * currentReserveA) / currentTotalSupply;
        withdrawnAmountB = (liquidityAmount * currentReserveB) / currentTotalSupply;
        
        // Validate minimum amounts for slippage protection
        require(withdrawnAmountA >= minimumAmountA, "InsufficientTokenAAmount");
        require(withdrawnAmountB >= minimumAmountB, "InsufficientTokenBAmount");

        // Transfer tokens to recipient
        require(IERC20(tokenA).transfer(recipient, withdrawnAmountA), "TokenATransferFailed");
        require(IERC20(tokenB).transfer(recipient, withdrawnAmountB), "TokenBTransferFailed");

        // Burn liquidity tokens from sender
        _burn(msg.sender, liquidityAmount);

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
        uint256 inputReserve = IERC20(tradingPath[0]).balanceOf(address(this));
        uint256 outputReserve = IERC20(tradingPath[1]).balanceOf(address(this));

        // Calculate output amount using AMM formula with fee
        uint256 actualOutput = _calculateSwapOutput(inputAmount, inputReserve, outputReserve);
        require(actualOutput >= minimumOutput, "InsufficientOutputAmount");

        // Execute token transfers
        require(IERC20(tradingPath[0]).transferFrom(msg.sender, address(this), inputAmount), "InputTransferFailed");
        require(IERC20(tradingPath[1]).transfer(recipient, actualOutput), "OutputTransferFailed");
        
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
     * @return currentPrice Price ratio scaled by PRECISION (1e18)
     */
    function getPrice(address tokenA, address tokenB) external view returns (uint256 currentPrice) {
        require(_isValidTokenPair(tokenA, tokenB), "UnsupportedTokenPair");
        
        uint256 reserveA = IERC20(tokenA).balanceOf(address(this));
        uint256 reserveB = IERC20(tokenB).balanceOf(address(this));
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
        
        // Apply 0.3% trading fee using constant product formula
        // Formula: outputAmount = (inputAmount * FEE_FACTOR * outputReserve) / (inputReserve * FEE_DENOMINATOR + inputAmount * FEE_FACTOR)
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
        return (tokenA == ekaToken && tokenB == ekbToken) || (tokenA == ekbToken && tokenB == ekaToken);
    }

    /**
     * @notice Returns current reserves of both tokens in the pool
     * @return ekaReserve Current EKA token balance in contract
     * @return ekbReserve Current EKB token balance in contract
     */
    function getReserves() external view returns (uint256 ekaReserve, uint256 ekbReserve) {
        ekaReserve = IERC20(ekaToken).balanceOf(address(this));
        ekbReserve = IERC20(ekbToken).balanceOf(address(this));
    }

    /**
     * @notice Returns the token addresses supported by this DEX
     * @return tokenA Address of EKA token contract
     * @return tokenB Address of EKB token contract
     */
    function getSupportedTokens() external view returns (address tokenA, address tokenB) {
        tokenA = ekaToken;
        tokenB = ekbToken;
    }
}