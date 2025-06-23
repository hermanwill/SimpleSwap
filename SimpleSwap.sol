// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SimpleSwap
 * @dev A simple decentralized exchange contract that mimics Uniswap functionality
 * @dev Supports swapping between two tokens: EKA (tokenA) and EKB (tokenB)
 */

// Interface for ERC-20 token standard
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SimpleSwap {
    // Token addresses for EKA and EKB
    address public immutable tokenEKA;
    address public immutable tokenEKB;
    
    // Liquidity pool reserves for the EKA-EKB pair
    uint256 public reserveEKA; // Reserve amount of EKA token in the pool
    uint256 public reserveEKB; // Reserve amount of EKB token in the pool
    
    // Liquidity shares tracking
    uint256 public totalLiquidity; // Total liquidity shares issued
    mapping(address => uint256) public liquidityShares; // User's liquidity shares
    
    // Events for transparency and monitoring
    event LiquidityAdded(
        address indexed provider, 
        uint256 amountA, 
        uint256 amountB, 
        uint256 liquidity
    );
    event LiquidityRemoved(
        address indexed provider, 
        uint256 amountA, 
        uint256 amountB, 
        uint256 liquidity
    );
    event TokensSwapped(
        address indexed user, 
        address indexed tokenIn, 
        address indexed tokenOut, 
        uint256 amountIn, 
        uint256 amountOut
    );
    
    /**
     * @dev Constructor to initialize the contract with EKA and EKB token addresses
     * @param _tokenEKA Address of the EKA token
     * @param _tokenEKB Address of the EKB token
     */
    constructor(address _tokenEKA, address _tokenEKB) {
        require(_tokenEKA != address(0) && _tokenEKB != address(0), "Invalid token addresses");
        require(_tokenEKA != _tokenEKB, "Tokens must be different");
        tokenEKA = _tokenEKA;
        tokenEKB = _tokenEKB;
    }
    
    /**
     * @dev Modifier to check if deadline has not passed
     * @param deadline Transaction deadline timestamp
     */
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Transaction expired");
        _;
    }
    
    /**
     * @dev Add liquidity to the ERC-20 token pair pool
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @param amountADesired Desired amount of tokenA to add
     * @param amountBDesired Desired amount of tokenB to add
     * @param amountAMin Minimum amount of tokenA to add (slippage protection)
     * @param amountBMin Minimum amount of tokenB to add (slippage protection)
     * @param to Address to receive the liquidity tokens
     * @param deadline Transaction deadline timestamp
     * @return amountA Actual amount of tokenA added
     * @return amountB Actual amount of tokenB added
     * @return liquidity Amount of liquidity tokens minted
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
        // Validate token addresses match our supported pair
        require(
            (tokenA == tokenEKA && tokenB == tokenEKB) || 
            (tokenA == tokenEKB && tokenB == tokenEKA), 
            "Invalid token pair"
        );
        require(to != address(0), "Invalid recipient address");
        
        // Determine if we're dealing with EKA-EKB or EKB-EKA order
        bool isEKAFirst = tokenA == tokenEKA;
        
        // Calculate optimal amounts based on current reserves
        if (totalLiquidity == 0) {
            // First liquidity provision - use desired amounts
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            // Calculate optimal amounts maintaining current ratio
            uint256 reserveA = isEKAFirst ? reserveEKA : reserveEKB;
            uint256 reserveB = isEKAFirst ? reserveEKB : reserveEKA;
            
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
        
        // Transfer tokens from user to contract
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "TokenA transfer failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "TokenB transfer failed");
        
        // Calculate liquidity tokens to mint
        if (totalLiquidity == 0) {
            // First liquidity provision - use geometric mean
            liquidity = sqrt(amountA * amountB);
        } else {
            // Calculate liquidity based on proportion of reserves
            uint256 reserveA = isEKAFirst ? reserveEKA : reserveEKB;
            liquidity = (amountA * totalLiquidity) / reserveA;
        }
        
        require(liquidity > 0, "Insufficient liquidity minted");
        
        // Update reserves
        if (isEKAFirst) {
            reserveEKA += amountA;
            reserveEKB += amountB;
        } else {
            reserveEKB += amountA;
            reserveEKA += amountB;
        }
        
        // Update liquidity tracking
        totalLiquidity += liquidity;
        liquidityShares[to] += liquidity;
        
        emit LiquidityAdded(to, amountA, amountB, liquidity);
    }
    
    /**
     * @dev Remove liquidity from the ERC-20 token pair pool
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @param liquidity Amount of liquidity tokens to burn
     * @param amountAMin Minimum amount of tokenA to receive (slippage protection)
     * @param amountBMin Minimum amount of tokenB to receive (slippage protection)
     * @param to Address to receive the tokens
     * @param deadline Transaction deadline timestamp
     * @return amountA Amount of tokenA received
     * @return amountB Amount of tokenB received
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
        // Validate token addresses match our supported pair
        require(
            (tokenA == tokenEKA && tokenB == tokenEKB) || 
            (tokenA == tokenEKB && tokenB == tokenEKA), 
            "Invalid token pair"
        );
        require(to != address(0), "Invalid recipient address");
        require(liquidity > 0, "Liquidity must be greater than zero");
        require(liquidityShares[msg.sender] >= liquidity, "Insufficient liquidity shares");
        require(totalLiquidity > 0, "No liquidity in pool");
        
        // Determine token order
        bool isEKAFirst = tokenA == tokenEKA;
        uint256 reserveA = isEKAFirst ? reserveEKA : reserveEKB;
        uint256 reserveB = isEKAFirst ? reserveEKB : reserveEKA;
        
        // Calculate proportional amounts to return
        amountA = (liquidity * reserveA) / totalLiquidity;
        amountB = (liquidity * reserveB) / totalLiquidity;
        
        // Check minimum amounts for slippage protection
        require(amountA >= amountAMin, "Insufficient A amount");
        require(amountB >= amountBMin, "Insufficient B amount");
        
        // Update reserves
        if (isEKAFirst) {
            reserveEKA -= amountA;
            reserveEKB -= amountB;
        } else {
            reserveEKB -= amountA;
            reserveEKA -= amountB;
        }
        
        // Update liquidity tracking
        totalLiquidity -= liquidity;
        liquidityShares[msg.sender] -= liquidity;
        
        // Transfer tokens back to user
        require(IERC20(tokenA).transfer(to, amountA), "TokenA transfer failed");
        require(IERC20(tokenB).transfer(to, amountB), "TokenB transfer failed");
        
        emit LiquidityRemoved(to, amountA, amountB, liquidity);
    }
    
    /**
     * @dev Swap exact amount of input tokens for output tokens
     * @param amountIn Amount of input tokens to swap
     * @param amountOutMin Minimum amount of output tokens to receive (slippage protection)
     * @param path Array of token addresses [tokenIn, tokenOut]
     * @param to Address to receive the output tokens
     * @param deadline Transaction deadline timestamp
     * @return amounts Array containing [amountIn, amountOut]
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(amountIn > 0, "Amount must be greater than zero");
        require(path.length == 2, "Invalid path length");
        require(to != address(0), "Invalid recipient address");
        
        address tokenIn = path[0];
        address tokenOut = path[1];
        
        // Validate tokens are in our supported pair
        require(
            (tokenIn == tokenEKA && tokenOut == tokenEKB) || 
            (tokenIn == tokenEKB && tokenOut == tokenEKA), 
            "Invalid token pair"
        );
        require(reserveEKA > 0 && reserveEKB > 0, "Insufficient liquidity");
        
        // Calculate output amount
        uint256 reserveIn = tokenIn == tokenEKA ? reserveEKA : reserveEKB;
        uint256 reserveOut = tokenIn == tokenEKA ? reserveEKB : reserveEKA;
        uint256 amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        
        require(amountOut >= amountOutMin, "Insufficient output amount");
        require(amountOut < reserveOut, "Insufficient reserve");
        
        // Transfer input tokens from user to contract
        //require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Input token transfer failed");
        
        // Update reserves
        //if (tokenIn == tokenEKA) {
          //  reserveEKA += amountIn;
            //reserveEKB -= amountOut;
        //} else {
          //  reserveEKB += amountIn;
            //reserveEKA -= amountOut;
        //}
        
        // Transfer output tokens to recipient
        require(IERC20(tokenOut).transfer(to, amountOut), "Output token transfer failed");
        
        // Prepare return array
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
        
        //emit TokensSwapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        
    }
    
    /**
     * @dev Get the price of tokenA in terms of tokenB
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @return price Price of tokenA in terms of tokenB (with 18 decimals precision)
     */
    function getPrice(address tokenA, address tokenB) external view returns (uint256 price) {
        // Validate tokens are in our supported pair
        require(
            (tokenA == tokenEKA && tokenB == tokenEKB) || 
            (tokenA == tokenEKB && tokenB == tokenEKA), 
            "Invalid token pair"
        );
        
        uint256 reserveA = tokenA == tokenEKA ? reserveEKA : reserveEKB;
        uint256 reserveB = tokenA == tokenEKA ? reserveEKB : reserveEKA;
        
        require(reserveA > 0, "No liquidity for tokenA");
        
        // Price of tokenA in terms of tokenB (how many tokenB for 1 tokenA)
        // Multiply by 1e18 for precision
        price = (reserveB * 1e18) / reserveA;
    }
    
    /**
     * @dev Calculate the amount of output tokens for a given input amount
     * @param amountIn Amount of input tokens
     * @param reserveIn Reserve of input token in the pool
     * @param reserveOut Reserve of output token in the pool
     * @return amountOut Amount of output tokens to be received
     */
    function getAmountOut(
        uint256 amountIn, 
        uint256 reserveIn, 
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
        
        // Apply 0.3% fee (997/1000 = 99.7% of input amount)
        // Using constant product formula: (x + Δx) * (y - Δy) = x * y
        // Solving for Δy: Δy = (y * Δx * 997) / (x * 1000 + Δx * 997)
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        
        amountOut = numerator / denominator;
    }
    
    // Internal helper functions
    
    /**
     * @dev Calculate square root using Babylonian method
     * @param x Input value
     * @return y Square root of x
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    // View functions for getting contract state
    
    /**
     * @dev Get the current reserves of EKA and EKB tokens
     * @return _reserveEKA Current reserve of EKA token
     * @return _reserveEKB Current reserve of EKB token
     */
    function getReserves() external view returns (uint256 _reserveEKA, uint256 _reserveEKB) {
        _reserveEKA = reserveEKA;
        _reserveEKB = reserveEKB;
    }
    
    /**
     * @dev Get liquidity shares of a specific address
     * @param user Address to check
     * @return shares Amount of liquidity shares owned by the user
     */
    function getLiquidityShares(address user) external view returns (uint256 shares) {
        shares = liquidityShares[user];
    }
    
    /**
     * @dev Get total liquidity in the pool
     * @return total Total amount of liquidity shares issued
     */
    function getTotalLiquidity() external view returns (uint256 total) {
        total = totalLiquidity;
    }
    
    /**
     * @dev Get the addresses of the supported token pair
     * @return _tokenEKA Address of EKA token
     * @return _tokenEKB Address of EKB token
     */
    function getTokenPair() external view returns (address _tokenEKA, address _tokenEKB) {
        _tokenEKA = tokenEKA;
        _tokenEKB = tokenEKB;
    }
}