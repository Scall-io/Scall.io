// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract fakeOracle {

    uint256 price;

    function setPrice(uint256 _price) public {
        price = _price;
    }

    function latestRoundData() public view returns(uint256, int256, uint256, uint256, uint256) {
        return (price, int(price), price, price, price);
    }

}