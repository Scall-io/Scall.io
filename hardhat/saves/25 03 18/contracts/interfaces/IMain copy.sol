// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IAutoReplacer {
    struct AutoReplaceInfos {
        uint256 index; // Market Index
        uint256 id; // ERC721 ID
    }
    function startAutoReplace(uint256 _index, uint256 _id) external;
    function stopAutoReplace(uint256 _id) external;
    function replace(uint256 _id) external;
    function replaceAll() external;
    function GetWithdrawableForLPForMaket(uint256 _index, uint256 _id) external view returns(uint256, uint256);
    function getAutoReplaceInfos(uint256 _id) external view returns(AutoReplaceInfos memory);

    
}