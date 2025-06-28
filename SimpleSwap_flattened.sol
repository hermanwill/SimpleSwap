
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;


/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol


// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC-20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC-721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in ERC-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC-1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * Both values are immutable: they can only be set once during construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner`'s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner`'s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// File: SimpleSwap.sol


pragma solidity ^0.8.0;

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