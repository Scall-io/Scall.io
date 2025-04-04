// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "./interfaces/IMarketPool.sol";

import "hardhat/console.sol";

contract Main {

    address private _COLLATERALPOOL;

    uint256 private _LIQUIDATIONTHRESHOLD;
    uint256 private _LIQUIDATIONPENALTY;
    uint256 private _MINCOLLATERAL;
    uint256 private _PROTOCOLFEES;

    uint256 private _marketCount;
    
    constructor()  {
        _LIQUIDATIONTHRESHOLD = 172800; // 2 days
        _LIQUIDATIONPENALTY = 12e16; // 12 %
        _MINCOLLATERAL = 604800; // 1 week
    }

    struct marketInfos {
        address addr;
        address tokenA;
        address tokenB;
        address priceFeed;
        uint256 range;
        uint256 yield;     
    }

    mapping(uint256 => marketInfos) private idToMarketInfos;
    mapping(address => uint256) private addressToId;

    function getMarketCount() public view returns(uint256) {
        return _marketCount;
    }

    function getMarketId(address _market) public view returns(uint256) {
        return addressToId[_market];
    }

    function getIdToMarket(uint256 _index) external view returns(address) {
        return idToMarketInfos[_index].addr;
    }

    function getIdToMarketInfos(uint256 _index) public view returns(marketInfos memory) {
        return idToMarketInfos[_index];
    }

    function linkMarket(address _contractAddress) public {
        marketInfos memory newMarket = marketInfos(_contractAddress, IMarketPool(_contractAddress).getTokenA(), IMarketPool(_contractAddress).getTokenB(), IMarketPool(_contractAddress).getPriceFeed(), IMarketPool(_contractAddress).getRange(), IMarketPool(_contractAddress).getYield());
        idToMarketInfos[_marketCount] = newMarket;
        addressToId[_contractAddress] = _marketCount;
        _marketCount++;
    }

    function updateMarket(address _contractAddress, address _priceFeed, uint256 _priceFeedDecimal, uint256 _range, uint256 _yield) public {
        IMarketPool(_contractAddress).setPriceFeed(_priceFeed, _priceFeedDecimal);
        IMarketPool(_contractAddress).setRange(_range);
        IMarketPool(_contractAddress).setYield(_yield);
    }

    // GET FUNCTION

    function getCollateralPool() public view returns(address) {
        return _COLLATERALPOOL;
    }

    function getLiquidationThreshold() public view returns(uint256) {
        return _LIQUIDATIONTHRESHOLD;
    }

    function getLiquidationPenalty() public view returns(uint256) {
        return _LIQUIDATIONPENALTY;
    }

    function getMinCollateral() public view returns(uint256) {
        return _MINCOLLATERAL;
    }

    // SET FUNCTION

    function setCollateralPool(address _address) public {
        _COLLATERALPOOL = _address;
    }

    function setLiquidationThreshold(uint256 _value) public {
        _LIQUIDATIONTHRESHOLD = _value;
    }

    function setLiquidationPenalty(uint256 _value) public {
        _LIQUIDATIONPENALTY = _value;
    }

    function setMinCollateral(uint256 _value) public {
        _MINCOLLATERAL = _value;
    }
    
}
