// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "./Ownable.sol";
import "./interfaces/IMarketPool.sol";

import "hardhat/console.sol";

contract Main is Ownable {

    event MarketLinked(address indexed admin, address market, uint256 marketId);
    event MarketUpdated(address indexed admin, address market);

    address private _COLLATERALPOOL;

    uint256 private _LIQUIDATIONTHRESHOLD;
    uint256 private _LIQUIDATIONPENALTY;
    uint256 private _MINCOLLATERAL;
    uint256 private _PROTOCOLFEES;

    uint256 private _marketCount;
    
    constructor() Ownable(msg.sender) {
        _LIQUIDATIONTHRESHOLD = 172800; // 2 days
        _LIQUIDATIONPENALTY = 12e16; // 12 %
        _MINCOLLATERAL = 604800; // 1 week
    }

    ////////////////////////////////////////////////////////////////// BASE FUNCTIONS //////////////////////////////////////////////////////////////////

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

    function setCollateralPool(address _address) public onlyOwner() {
        _COLLATERALPOOL = _address;
    }

    function setLiquidationThreshold(uint256 _value) public onlyOwner() {
        _LIQUIDATIONTHRESHOLD = _value;
    }

    function setLiquidationPenalty(uint256 _value) public onlyOwner() {
        _LIQUIDATIONPENALTY = _value;
    }

    function setMinCollateral(uint256 _value) public onlyOwner() {
        _MINCOLLATERAL = _value;
    }

    ////////////////////////////////////////////////////////////////// SET UP //////////////////////////////////////////////////////////////////

    struct marketInfos {
        address addr;
        address tokenA;
        address tokenB;
        address priceFeed;
        uint256 range;
        uint256 yield;     
    }

    mapping(uint256 => marketInfos) private _idToMarketInfos;
    mapping(address => uint256) private _addressToId;

    ////////////////////////////////////////////////////////////////// GET FUNCTIONS //////////////////////////////////////////////////////////////////

    function getMarketCount() public view returns(uint256) {
        return _marketCount;
    }

    function getMarketId(address _market) public view returns(uint256) {
        return _addressToId[_market];
    }

    function getIdToMarket(uint256 _index) external view returns(address) {
        return _idToMarketInfos[_index].addr;
    }

    function getIdToMarketInfos(uint256 _index) public view returns(marketInfos memory) {
        return _idToMarketInfos[_index];
    }

    ////////////////////////////////////////////////////////////////// USERS FUNCTIONS //////////////////////////////////////////////////////////////////

    function linkMarket(address _contractAddress) public onlyOwner() {
        IMarketPool market = IMarketPool(_contractAddress);
        marketInfos memory newMarket = marketInfos(
            _contractAddress,
            market.getTokenA(),
            market.getTokenB(),
            market.getPriceFeed(),
            market.getRange(),
            market.getYield()
        );
        _idToMarketInfos[_marketCount] = newMarket;
        _addressToId[_contractAddress] = _marketCount;

        // Emit event for market link
        emit MarketLinked(msg.sender, _contractAddress, _marketCount);

        _marketCount++;
    }

    function updateMarket(address _contractAddress, address _priceFeed, uint256 _priceFeedDecimal, uint256 _range, uint256 _yield) public onlyOwner() {
        IMarketPool(_contractAddress).setPriceFeed(_priceFeed, _priceFeedDecimal);
        IMarketPool(_contractAddress).setRange(_range);
        IMarketPool(_contractAddress).setYield(_yield);

        // Emit event for market link
        emit MarketUpdated(msg.sender, _contractAddress);
    }
    
}
