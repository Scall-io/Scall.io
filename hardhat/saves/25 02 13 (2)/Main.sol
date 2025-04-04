// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./interfaces/IMarketPool.sol";
import "./interfaces/ICollateralPool.sol";

/// @title Main
/// @notice This contract brings together the different variables of the protocol, and also allows them to be modified by the owner.
contract Main is Ownable {

    event MarketLinked(address indexed admin, address market, uint256 marketId);
    event MarketUpdated(address indexed admin, address market);

    address private _COLLATERALPOOL;
    address private _COLLATERALTOKEN;
    uint256 private _COLLATERALTOKEN_DECIMALS;

    uint256 private _LIQUIDATIONTHRESHOLD;
    uint256 private _LIQUIDATIONPENALTY;
    uint256 private _MINCOLLATERAL;
    uint256 private _PROTOCOLFEES;

    uint256 private _marketCount;

    /// @param _collateralToken Address of the collateral token used in the protocol    
    constructor(address _collateralToken) Ownable(msg.sender) {
        _COLLATERALTOKEN = _collateralToken;
        _LIQUIDATIONTHRESHOLD = 172800; // 2 days
        _LIQUIDATIONPENALTY = 12e16; // 12 %
        _MINCOLLATERAL = 604800; // 1 week
        //_PROTOCOLFEES = 10e16; // 10%
    }

    ////////////////////////////////////////////////////////////////// BASE FUNCTIONS //////////////////////////////////////////////////////////////////

    /// @notice Retrieves the address of the collateral token
    /// @return Address of the collateral token
    function getCollateralToken() external view returns(address) {
        return _COLLATERALTOKEN;
    }

    /// @notice Retrieves the address of the collateral pool
    /// @return Address of the collateral pool
    function getCollateralPool() external view returns(address) {
        return _COLLATERALPOOL;
    }

    /// @notice Retrieves the liquidation threshold time
    /// @return Liquidation threshold time in seconds
    function getLiquidationThreshold() external view returns(uint256) {
        return _LIQUIDATIONTHRESHOLD;
    }

    /// @notice Retrieves the liquidation penalty rate
    /// @return Liquidation penalty rate as a percentage (scaled by 1e18)
    function getLiquidationPenalty() external view returns(uint256) {
        return _LIQUIDATIONPENALTY;
    }

    /// @notice Retrieves the minimum collateral requirement
    /// @return Minimum collateral required in seconds
    function getMinCollateral() external view returns(uint256) {
        return _MINCOLLATERAL;
    }

    /// @notice Retrieves the protocol fees rate
    /// @return Protocol fees rate as a percentage (scaled by 1e18)
    function getFees() external view returns(uint256) {
        return _PROTOCOLFEES;
    }

    /// @notice Sets the address of the collateral pool
    /// @dev Only callable by the contract owner. Requires that the collateral token matches.
    /// @param _address Address of the collateral pool
    function setCollateralPool(address _address) external onlyOwner() {
        require(ICollateralPool(_address).getCollateralToken() == _COLLATERALTOKEN, "Wrong Collateral Token");
        _COLLATERALPOOL = _address;
    }

    /// @notice Sets the liquidation threshold time
    /// @dev Only callable by the contract owner
    /// @param _value New liquidation threshold time in seconds
    function setLiquidationThreshold(uint256 _value) external onlyOwner() {
        _LIQUIDATIONTHRESHOLD = _value;
    }

    /// @notice Sets the liquidation penalty rate
    /// @dev Only callable by the contract owner. Penalty should be ≤ 100% (1e18).
    /// @param _value New liquidation penalty rate as a percentage (scaled by 1e18)
    function setLiquidationPenalty(uint256 _value) external onlyOwner() {
        require(_value <= 1e18, "Penalty too high");
        _LIQUIDATIONPENALTY = _value;
    }

    /// @notice Sets the minimum collateral requirement
    /// @dev Only callable by the contract owner
    /// @param _value New minimum collateral time requirement in seconds
    function setMinCollateral(uint256 _value) external onlyOwner() {
        _MINCOLLATERAL = _value;
    }

    /// @notice Sets the protocol fees rate
    /// @dev Only callable by the contract owner. Fees should be ≤ 100% (1e18).
    /// @param _value New protocol fees rate as a percentage (scaled by 1e18)
    function setProtocolFees(uint256 _value) external onlyOwner() {
        require(_value <= 1e18, "Fees too high");
        _PROTOCOLFEES = _value;
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

    /// @notice Retrieves the total count of linked markets
    /// @return Total number of linked markets
    function getMarketCount() external view returns(uint256) {
        return _marketCount;
    }

    /// @notice Retrieves the market ID associated with a market address
    /// @param _market Address of the market
    /// @return ID of the market
    function getMarketId(address _market) external view returns(uint256) {
        return _addressToId[_market];
    }

    /// @notice Retrieves the market address for a given market ID
    /// @param _index Market ID
    /// @return Address of the market
    function getIdToMarket(uint256 _index) external view returns(address) {
        return _idToMarketInfos[_index].addr;
    }

    /// @notice Retrieves detailed information for a market based on its ID
    /// @param _index Market ID
    /// @return Market information including address, tokens, price feed, range, and yield
    function getIdToMarketInfos(uint256 _index) external view returns(marketInfos memory) {
        return _idToMarketInfos[_index];
    }

    ////////////////////////////////////////////////////////////////// USERS FUNCTIONS //////////////////////////////////////////////////////////////////

    /// @notice Links a new market to the protocol
    /// @dev Only callable by the contract owner. Requires that tokenB matches the collateral token.
    /// @param _contractAddress Address of the market contract to link
    function linkMarket(address _contractAddress) external onlyOwner() {
        require(IMarketPool(_contractAddress).getTokenB() == _COLLATERALTOKEN, "Wrong Token B");
        require(_addressToId[_contractAddress] == 0 && _idToMarketInfos[0].addr != _contractAddress , "Market already linked");
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

    /// @notice Updates an existing market's price feed, range, and yield
    /// @dev Only callable by the contract owner
    /// @param _contractAddress Address of the market to update
    /// @param _priceFeed New address for the price feed
    /// @param _priceFeedDecimal Decimal precision of the price feed
    /// @param _range New range value for the market
    /// @param _yield New yield percentage (scaled by 1e18)
    function updateMarket(address _contractAddress, address _priceFeed, uint256 _priceFeedDecimal, uint256 _range, uint256 _yield) external onlyOwner() {
        IMarketPool(_contractAddress).setPriceFeed(_priceFeed, _priceFeedDecimal);
        IMarketPool(_contractAddress).setRange(_range);
        IMarketPool(_contractAddress).setYield(_yield);

        marketInfos memory newMarketInfos = marketInfos(
            _contractAddress,
            _idToMarketInfos[_addressToId[_contractAddress]].tokenA,
            _idToMarketInfos[_addressToId[_contractAddress]].tokenB,
            _priceFeed,
            _range,
            _yield
        );
        _idToMarketInfos[_addressToId[_contractAddress]] = newMarketInfos;

        // Emit event for market link
        emit MarketUpdated(msg.sender, _contractAddress);
    }
    
}
