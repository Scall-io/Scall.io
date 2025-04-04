// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IMain {
    struct marketInfos {
        address addr;
        address tokenA;
        address tokenB;
        address priceFeed;
        uint256 range;
        uint256 yield;     
    }
    function getCollateralToken() external view returns(address);
    function getCollateralTokenDecimals() external view returns(uint256);
    function getCollateralPool() external view returns(address);
    function getLiquidationThreshold() external view returns(uint256);
    function getLiquidationPenalty() external view returns(uint256);
    function getMinCollateral() external view returns(uint256);
    function getFees() external view returns(uint256);
    function getMarketCount() external view returns(uint256);
    function getMarketId(address _market) external view returns(uint256);
    function getIdToMarket(uint256 _index) external view returns(address);
    function getIdToMarketInfos(uint256 _index) external view returns(marketInfos memory);
}