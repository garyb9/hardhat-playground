// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20.sol";

contract BUSD is ERC20 {

    constructor (uint256 amount) ERC20("BUSD Token", "BUSD") public {
        _mint(msg.sender, amount * (10 ** uint256(decimals())));
    }

}