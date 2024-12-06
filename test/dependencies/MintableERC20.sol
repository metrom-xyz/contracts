pragma solidity 0.8.28;

import {ERC20} from "oz/token/ERC20/ERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract MintableERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
