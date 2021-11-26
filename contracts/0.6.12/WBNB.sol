// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20.sol";

contract WBNB is ERC20 {

    constructor (uint256 amount) ERC20("Wrapped BNB", "WBNB") public {
        _mint(msg.sender, amount * (10 ** uint256(decimals())));
    }

}