// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IMarketPool {
    struct StrikeInfos {
        uint256 callLP;
        uint256 callLU;
        uint256 callLR;
        uint256 putLP;
        uint256 putLU;
        uint256 putLR;
        uint256 updateCount;
        uint256 updated;
    }  
    struct LpInfos {
        bool isCall;
        uint256 strike;
        uint256 amount;
        uint256 start;
        uint256 lastClaim;
    }
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
    function getLpInfos(uint256 _id) external view returns(LpInfos memory);
    function getStrikeInfos(uint256 _strike) external view returns(StrikeInfos memory);
    function getStrikeHistory(uint256 _strike, uint256 _index) external view returns(StrikeInfos memory);
    function getRewards(uint256 _id) external view returns(uint256);
    function claimRewards(uint256 _id) external returns(uint256 rewards);
    function closeContract(uint256 _id) external;
    function liquidateContract(uint256 _id) external;
    function setPriceFeed(address _priceFeed, uint256 _decimal) external;
    function setIntervalLength(uint256 _length) external;
    function setRange(uint256 _range) external;
    function setYield(uint256 _yield) external;
    function getTokenA() external view returns(address);
    function getTokenB() external view returns(address);
    function getPriceFeed() external view returns(address);
    function getIntervalLength() external view returns(uint256);
    function getRange() external view returns(uint256);
    function getYield() external view returns(uint256);
    function getPrice() external view returns(uint256);
    function withdraw(uint256 _id) external;
}