// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenAB is ERC20 {
    constructor(address recipient) ERC20("TokenAB", "TEK")  {
        _mint(recipient, 1000 * 10 ** decimals());
    }

}
