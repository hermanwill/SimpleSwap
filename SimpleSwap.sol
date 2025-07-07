// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract SimpleSwap {
    // ERC20 LP Token Properties
    string public name = "SimpleSwap Liquidity Token";
    string public symbol = "SSLT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // ERC20 LP Token Mappings
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Token Pair Addresses
    address public tokenA;
    address public tokenB;

    // Reserve Management
    uint256 public reserveA;
    uint256 public reserveB;

    // Constants
    uint256 private constant MINIMUM_LIQUIDITY = 1000;

    // Events for LP Token
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Events for SimpleSwap
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokensSwapped(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token addresses");
        require(_tokenA != _tokenB, "Identical tokens");
        tokenA = _tokenA;
        tokenB = _tokenB;
        
        // Mint minimum liquidity to prevent total drain
        _mint(address(this), MINIMUM_LIQUIDITY);
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Transaction expired");
        _;
    }

    // Internal ERC20 Functions
    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(balanceOf[from] >= amount, "Burn exceeds balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    // ERC20 Standard Functions
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // SimpleSwap Core Functions
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(_isValidTokenPair(_tokenA, _tokenB), "Invalid token pair");
        require(to != address(0), "Invalid recipient");

        if (reserveA == 0 && reserveB == 0) {
            // First liquidity provision
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            // Calculate optimal amounts
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

        // Transfer tokens
        require(IERC20(_tokenA).transferFrom(msg.sender, address(this), amountA), "Transfer A failed");
        require(IERC20(_tokenB).transferFrom(msg.sender, address(this), amountB), "Transfer B failed");

        // Calculate liquidity
        if (totalSupply == MINIMUM_LIQUIDITY) {
            liquidity = _sqrt(amountA * amountB);
        } else {
            uint256 liquidityA = (amountA * totalSupply) / reserveA;
            uint256 liquidityB = (amountB * totalSupply) / reserveB;
            liquidity = liquidityA < liquidityB ? liquidityA : liquidityB;
        }

        require(liquidity > 0, "Insufficient liquidity minted");

        // Update reserves and mint LP tokens
        reserveA += amountA;
        reserveB += amountB;
        _mint(to, liquidity);

        emit LiquidityAdded(to, amountA, amountB, liquidity);
    }

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        require(_isValidTokenPair(_tokenA, _tokenB), "Invalid token pair");
        require(to != address(0), "Invalid recipient");
        require(liquidity > 0, "Zero liquidity");
        require(balanceOf[msg.sender] >= liquidity, "Insufficient liquidity balance");

        // Calculate withdrawal amounts
        amountA = (liquidity * reserveA) / totalSupply;
        amountB = (liquidity * reserveB) / totalSupply;

        require(amountA >= amountAMin, "Insufficient A amount");
        require(amountB >= amountBMin, "Insufficient B amount");

        // Burn LP tokens and update reserves
        _burn(msg.sender, liquidity);
        reserveA -= amountA;
        reserveB -= amountB;

        // Transfer tokens
        require(IERC20(_tokenA).transfer(to, amountA), "Transfer A failed");
        require(IERC20(_tokenB).transfer(to, amountB), "Transfer B failed");

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

        address tokenIn = path[0];
        address tokenOut = path[1];

        // Determine reserves
        uint256 reserveIn = tokenIn == tokenA ? reserveA : reserveB;
        uint256 reserveOut = tokenOut == tokenA ? reserveA : reserveB;

        // Calculate output amount
        uint256 amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "Insufficient output amount");

        // Execute transfers
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Input transfer failed");
        require(IERC20(tokenOut).transfer(to, amountOut), "Output transfer failed");

        // Update reserves
        if (tokenIn == tokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        emit TokensSwapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function getPrice(address _tokenA, address _tokenB) external view returns (uint256 price) {
        require(_isValidTokenPair(_tokenA, _tokenB), "Invalid token pair");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");
        
        if (_tokenA == tokenA) {
            price = (reserveB * 1e18) / reserveA;
        } else {
            price = (reserveA * 1e18) / reserveB;
        }
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) 
        public pure returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient reserves");
        
        // Simple constant product formula without fees (as per original requirement)
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }

    // Internal helper functions
    function _isValidTokenPair(address _tokenA, address _tokenB) internal view returns (bool) {
        return (_tokenA == tokenA && _tokenB == tokenB) || (_tokenA == tokenB && _tokenB == tokenA);
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // View functions
    function getReserves() external view returns (uint256 _reserveA, uint256 _reserveB) {
        _reserveA = reserveA;
        _reserveB = reserveB;
    }

    function getSupportedTokens() external view returns (address _tokenA, address _tokenB) {
        _tokenA = tokenA;
        _tokenB = tokenB;
    }

    function getLiquidityShares(address user) external view returns (uint256 shares) {
        return balanceOf[user];
    }

    function getTotalLiquidity() external view returns (uint256 total) {
        return totalSupply;
    }
}