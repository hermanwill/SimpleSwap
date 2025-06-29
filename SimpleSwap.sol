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
    uint256 private constant INITIAL_RESERVE = 1;

    /// @notice Minimum liquidity tokens locked permanently on first provision
    uint256 private constant MINIMUM_LOCKED_LIQUIDITY = 1000;

    /// @notice TokenA (EKA) contract instance
    TokenA public immutable tokenEKA;
    
    /// @notice TokenB (EKB) contract instance
    TokenB public immutable tokenEKB;

    /// @notice Total liquidity shares issued
    uint256 public totalLiquidity;
    
    /// @notice Mapping of user addresses to their liquidity shares
    mapping(address => uint256) public liquidityShares;

    /// @notice Emitted when liquidity is added to the pool
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    
    /// @notice Emitted when liquidity is removed from the pool
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    
    /// @notice Emitted when tokens are swapped
    event TokensSwapped(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /**
     * @dev Constructor initializes the contract with TokenA and TokenB instances
     * @param _tokenEKA Address of the deployed TokenA (EKA) contract
     * @param _tokenEKB Address of the deployed TokenB (EKB) contract
     */
    constructor(address _tokenEKA, address _tokenEKB) {
        require(_tokenEKA != address(0) && _tokenEKB != address(0), "Invalid token addresses");
        require(_tokenEKA != _tokenEKB, "Identical tokens");
        
        tokenEKA = TokenA(_tokenEKA);
        tokenEKB = TokenB(_tokenEKB);
        
        // Initialize with minimum liquidity to prevent total drain
        totalLiquidity = MINIMUM_LOCKED_LIQUIDITY;
    }

    /// @notice Validates that function is called before specified deadline
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Transaction expired");
        _;
    }

    /**
     * @notice Adds liquidity to the EKA/EKB trading pair
     * @param tokenA Address of first token (must be EKA or EKB)
     * @param tokenB Address of second token (must be EKA or EKB)
     * @param amountADesired Maximum amount of tokenA willing to deposit
     * @param amountBDesired Maximum amount of tokenB willing to deposit
     * @param amountAMin Minimum amount of tokenA to accept
     * @param amountBMin Minimum amount of tokenB to accept
     * @param to Address that will receive the liquidity tokens
     * @param deadline Transaction deadline timestamp
     * @return amountA Actual amount of tokenA deposited
     * @return amountB Actual amount of tokenB deposited
     * @return liquidity Amount of LP tokens minted to recipient
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        
        require(_isValidTokenPair(tokenA, tokenB), "Invalid token pair");
        require(to != address(0), "Invalid recipient");
        
        // Get current reserves
        uint256 reserveA = _getTokenBalance(tokenA);
        uint256 reserveB = _getTokenBalance(tokenB);
        
        // Handle empty pool case
        if (reserveA == 0 && reserveB == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            // Calculate optimal amounts based on current reserves
            uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Insufficient B amount");
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
                require(amountAOptimal <= amountADesired && amountAOptimal >= amountAMin, "Insufficient A amount");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }

        // Calculate liquidity to mint
        if (totalLiquidity == MINIMUM_LOCKED_LIQUIDITY) {
            // First liquidity provision
            liquidity = _sqrt(amountA * amountB);
        } else {
            uint256 liquidityA = (amountA * totalLiquidity) / reserveA;
            uint256 liquidityB = (amountB * totalLiquidity) / reserveB;
            liquidity = liquidityA < liquidityB ? liquidityA : liquidityB;
        }

        require(liquidity > 0, "Insufficient liquidity minted");

        // Execute transfers
        require(_transferTokensFrom(tokenA, msg.sender, address(this), amountA), "Token A transfer failed");
        require(_transferTokensFrom(tokenB, msg.sender, address(this), amountB), "Token B transfer failed");
        
        // Update liquidity tracking
        totalLiquidity += liquidity;
        liquidityShares[to] += liquidity;

        emit LiquidityAdded(to, amountA, amountB, liquidity);
    }

    /**
     * @notice Removes liquidity from the pool by burning LP tokens
     * @param tokenA Address of first token (must be EKA or EKB)
     * @param tokenB Address of second token (must be EKA or EKB)
     * @param liquidity Amount of LP tokens to burn
     * @param amountAMin Minimum amount of tokenA to receive
     * @param amountBMin Minimum amount of tokenB to receive
     * @param to Address that will receive the underlying tokens
     * @param deadline Transaction deadline timestamp
     * @return amountA Amount of tokenA returned to recipient
     * @return amountB Amount of tokenB returned to recipient
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB) {
    
        require(_isValidTokenPair(tokenA, tokenB), "Invalid token pair");
        require(to != address(0), "Invalid recipient");
        require(liquidity > 0, "Zero liquidity");
        require(liquidityShares[msg.sender] >= liquidity, "Insufficient liquidity shares");
        
        // Get current reserves
        uint256 reserveA = _getTokenBalance(tokenA);
        uint256 reserveB = _getTokenBalance(tokenB);
        
        // Calculate proportional token amounts to return
        amountA = (liquidity * reserveA) / totalLiquidity;
        amountB = (liquidity * reserveB) / totalLiquidity;
        
        // Validate minimum amounts
        require(amountA >= amountAMin, "Insufficient A amount");
        require(amountB >= amountBMin, "Insufficient B amount");

        // Update liquidity tracking first
        liquidityShares[msg.sender] -= liquidity;
        totalLiquidity -= liquidity;

        // Execute transfers
        require(_transferTokens(tokenA, to, amountA), "Token A transfer failed");
        require(_transferTokens(tokenB, to, amountB), "Token B transfer failed");

        emit LiquidityRemoved(to, amountA, amountB, liquidity);
    }

    /**
     * @notice Swaps exact input tokens for output tokens
     * @param amountIn Exact amount of input tokens to trade
     * @param amountOutMin Minimum acceptable amount of output tokens
     * @param path Array containing [inputToken, outputToken] addresses
     * @param to Address that will receive the output tokens
     * @param deadline Transaction deadline timestamp
     * @return amounts Array containing [inputAmount, actualOutputAmount]
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        
        require(path.length == 2, "Invalid path");
        require(to != address(0), "Invalid recipient");
        require(_isValidTokenPair(path[0], path[1]), "Invalid token pair");

        // Get current reserves
        uint256 reserveIn = _getTokenBalance(path[0]);
        uint256 reserveOut = _getTokenBalance(path[1]);

        // Calculate output amount using getAmountOut (NO FEES)
        uint256 amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "Insufficient output amount");

        // Execute transfers
        require(_transferTokensFrom(path[0], msg.sender, address(this), amountIn), "Input transfer failed");
        require(_transferTokens(path[1], to, amountOut), "Output transfer failed");
        
        // Prepare return array
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
        
        emit TokensSwapped(msg.sender, path[0], path[1], amountIn, amountOut);
    }

    /**
     * @notice Returns current price of tokenA in terms of tokenB
     * @param tokenA Base token address
     * @param tokenB Quote token address  
     * @return price Price ratio
     */
    function getPrice(address tokenA, address tokenB) external view returns (uint256 price) {
        require(_isValidTokenPair(tokenA, tokenB), "Invalid token pair");
        
        uint256 reserveA = _getTokenBalance(tokenA);
        uint256 reserveB = _getTokenBalance(tokenB);
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");
        
        return (reserveB * 1e18) / reserveA;
    }

    /**
     * @notice Calculates expected output amount for a given input
     * @param amountIn Amount of input tokens
     * @param reserveIn Current reserve of input token
     * @param reserveOut Current reserve of output token
     * @return amountOut Calculated output amount
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) 
        public pure returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient reserves");
        
        // Simple constant product formula WITHOUT FEES
        return (amountIn * reserveOut) / (reserveIn + amountIn);
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
            revert("Unsupported token");
        }
    }

    /**
     * @dev Internal function to transfer tokens from one address to another
     * @param token Token address to transfer
     * @param from Source address
     * @param to Destination address
     * @param amount Amount to transfer
     * @return success True if transfer was successful
     */
    function _transferTokensFrom(address token, address from, address to, uint256 amount) internal returns (bool success) {
        if (token == address(tokenEKA)) {
            return tokenEKA.transferFrom(from, to, amount);
        } else if (token == address(tokenEKB)) {
            return tokenEKB.transferFrom(from, to, amount);
        } else {
            return false;
        }
    }

    /**
     * @dev Internal function to transfer tokens from this contract to another address
     * @param token Token address to transfer
     * @param to Destination address
     * @param amount Amount to transfer
     * @return success True if transfer was successful
     */
    function _transferTokens(address token, address to, uint256 amount) internal returns (bool success) {
        if (token == address(tokenEKA)) {
            return tokenEKA.transfer(to, amount);
        } else if (token == address(tokenEKB)) {
            return tokenEKB.transfer(to, amount);
        } else {
            return false;
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
     * @return reserveEKA Current EKA token balance in contract
     * @return reserveEKB Current EKB token balance in contract
     */
    function getReserves() external view returns (uint256 reserveEKA, uint256 reserveEKB) {
        reserveEKA = tokenEKA.balanceOf(address(this));
        reserveEKB = tokenEKB.balanceOf(address(this));
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
