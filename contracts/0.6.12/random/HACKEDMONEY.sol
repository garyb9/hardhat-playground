// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20.sol";

contract HACKEDMONEY is ERC20 {

    constructor (uint256 amount) ERC20("HACKEDMONEY LOL", "HACKEDMONEY") public {
        _mint(msg.sender, amount * (10 ** uint256(decimals())));
    }

}