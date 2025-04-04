// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract fakeToken is ERC20 {

    uint8 private _DECIMALS;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol) {
        _DECIMALS = _decimals;
        _mint(msg.sender, 1000000000000000000000000000);
    }

    function decimals() public view virtual override returns (uint8) {
        return _DECIMALS;
    }

}