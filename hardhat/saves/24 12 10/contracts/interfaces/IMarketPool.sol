// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IMarketPool {
    struct ContractInfos {
        bool isCall;
        uint256 strike;
        uint256 amount;
        uint256 rent;
        uint256 start;
    }
    function getERC721_Contract() external view returns(address);
    function getERC721_LP() external view returns(address);
    function getContractInfos(uint256 _id) external view returns(ContractInfos memory);
    function closeContract(uint256 _id) external;
    function setPriceFeed(address _priceFeed, uint256 _decimal) external;
    function setRange(uint256 _range) external;
    function setYield(uint256 _yield) external;
    function getTokenA() external view returns(address);
    function getTokenB() external view returns(address);
    function getPriceFeed() external view returns(address);
    function getRange() external view returns(uint256);
    function getYield() external view returns(uint256);
}