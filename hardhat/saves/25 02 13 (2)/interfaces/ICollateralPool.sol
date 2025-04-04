// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ICollateralPool {
    struct UserInfos {
        uint256 collateral;
        uint256 rent;
        uint256 lastUpdate;
    }
    function getCollateralToken() external view returns(address);
    function getUserInfos(address _user) external view returns(UserInfos memory);
    function balanceOf(address _user) external view returns(uint256);
    function updateUserInfos(address _user, bool _isAdding, uint256 _rent, uint256 _lastUpdate) external;
    function canOpenContract(address _user, uint256 _rent) external view returns(bool);
    function claimRewards(uint256 _index, uint256 _id) external;
    function needLiquidation(address _user) external view returns(bool);
}