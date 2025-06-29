// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleSwap {
    
    address public tokenEKA;
    address public tokenEKB;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidityShares;
    
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokensSwapped(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenEKA, address _tokenEKB) {
        require(_tokenEKA != address(0), "Invalid tokenEKA");
        require(_tokenEKB != address(0), "Invalid tokenEKB");
        require(_tokenEKA != _tokenEKB, "Tokens must be different");
        
        tokenEKA = _tokenEKA;
        tokenEKB = _tokenEKB;
        totalLiquidity = 1000;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Transaction expired");
        _;
    }

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
        
        (amountA, amountB, liquidity) = _calculateLiquidityAmounts(
            tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin
        );

        _executeTransferFrom(tokenA, msg.sender, address(this), amountA);
        _executeTransferFrom(tokenB, msg.sender, address(this), amountB);
        
        totalLiquidity += liquidity;
        liquidityShares[to] += liquidity;

        emit LiquidityAdded(to, amountA, amountB, liquidity);
    }

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
        
        (amountA, amountB) = _calculateWithdrawalAmounts(tokenA, tokenB, liquidity, amountAMin, amountBMin);

        liquidityShares[msg.sender] -= liquidity;
        totalLiquidity -= liquidity;

        _executeTransfer(tokenA, to, amountA);
        _executeTransfer(tokenB, to, amountB);

        emit LiquidityRemoved(to, amountA, amountB, liquidity);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) {
        
        require(path.length == 2, "Invalid path");
        require(to != address(0), "Invalid recipient");
        require(_isValidTokenPair(path[0], path[1]), "Invalid token pair");

        uint256 amountOut = _calculateSwapAmounts(path[0], path[1], amountIn, amountOutMin);

        _executeTransferFrom(path[0], msg.sender, address(this), amountIn);
        _executeTransfer(path[1], to, amountOut);
        
        emit TokensSwapped(msg.sender, path[0], path[1], amountIn, amountOut);
    }

    function getPrice(address tokenA, address tokenB) external view returns (uint256 price) {
        require(_isValidTokenPair(tokenA, tokenB), "Invalid token pair");
        
        uint256 reserveA = _getBalance(tokenA);
        uint256 reserveB = _getBalance(tokenB);
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");
        
        return (reserveB * 1e18) / reserveA;
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) 
        public pure returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient reserves");
        
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }

    // Internal helper functions to avoid stack too deep

    function _calculateLiquidityAmounts(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        
        uint256 reserveA = _getBalance(tokenA);
        uint256 reserveB = _getBalance(tokenB);
        
        if (reserveA == 0 && reserveB == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
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

        if (totalLiquidity == 1000) {
            liquidity = _sqrt(amountA * amountB);
        } else {
            uint256 liquidityA = (amountA * totalLiquidity) / reserveA;
            uint256 liquidityB = (amountB * totalLiquidity) / reserveB;
            liquidity = liquidityA < liquidityB ? liquidityA : liquidityB;
        }

        require(liquidity > 0, "Insufficient liquidity minted");
    }

    function _calculateWithdrawalAmounts(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB) {
        
        uint256 reserveA = _getBalance(tokenA);
        uint256 reserveB = _getBalance(tokenB);
        
        amountA = (liquidity * reserveA) / totalLiquidity;
        amountB = (liquidity * reserveB) / totalLiquidity;
        
        require(amountA >= amountAMin, "Insufficient A amount");
        require(amountB >= amountBMin, "Insufficient B amount");
    }

    function _calculateSwapAmounts(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    ) internal view returns (uint256 amountOut) {
        
        uint256 reserveIn = _getBalance(tokenIn);
        uint256 reserveOut = _getBalance(tokenOut);

        amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "Insufficient output amount");
    }

    function _getBalance(address token) internal view returns (uint256 balance) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", address(this)));
        require(success, "Failed to get balance");
        balance = abi.decode(data, (uint256));
    }

    function _executeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success,) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount));
        require(success, "Transfer failed");
    }

    function _executeTransfer(address token, address to, uint256 amount) internal {
        (bool success,) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        require(success, "Transfer failed");
    }

    function _isValidTokenPair(address tokenA, address tokenB) internal view returns (bool) {
        return (tokenA == tokenEKA && tokenB == tokenEKB) || 
               (tokenA == tokenEKB && tokenB == tokenEKA);
    }

    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function getReserves() external view returns (uint256 reserveEKA, uint256 reserveEKB) {
        reserveEKA = _getBalance(tokenEKA);
        reserveEKB = _getBalance(tokenEKB);
    }

    function getSupportedTokens() external view returns (address tokenA, address tokenB) {
        tokenA = tokenEKA;
        tokenB = tokenEKB;
    }

    function getLiquidityShares(address user) external view returns (uint256 shares) {
        return liquidityShares[user];
    }

    function getTotalLiquidity() external view returns (uint256 total) {
        return totalLiquidity;
    }
}