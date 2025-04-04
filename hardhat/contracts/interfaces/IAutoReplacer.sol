// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IAutoReplacer {
    struct AutoReplaceInfos {
        uint256 index;
        uint256 id;
        uint256 rewards;
    }
    function startAutoReplace(uint256 _index, uint256 _id) external;
    function stopAutoReplace(uint256 _id) external;
    function replace(uint256 _id) external;
    function replaceAll() external;
    function claimRewards(uint256 _replacerID) external returns(uint256);
    function GetWithdrawableForLPForMaket(uint256 _index, uint256 _id) external view returns(uint256, uint256);
    function getAutoReplaceInfos(uint256 _id) external view returns(AutoReplaceInfos memory);
    function getERC721_AutoReplace() external view returns(address);

    
}