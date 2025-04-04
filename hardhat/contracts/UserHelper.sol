// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interfaces/IMain.sol";
import "./interfaces/ICollateralPool.sol";
import "./interfaces/IMarketPool.sol";
import "./interfaces/IAutoReplacer.sol";
import "./interfaces/IERC721x.sol";

contract UserHelper {

    address private _MAIN;
    address private _AUTOREPLACER;
    
    constructor(address _main, address _autoReplacer) {
        _MAIN = _main;
        _AUTOREPLACER = _autoReplacer;
    }

    function getMain() external view returns(address) {
        return _MAIN;
    }

    function getAutoReplacer() external view returns(address) {
        return _AUTOREPLACER;
    }

    function claimAllNonAutoReplaceRewards() public {
        ICollateralPool collateralPool = ICollateralPool(IMain(_MAIN).getCollateralPool());
        uint256 marketCount = IMain(_MAIN).getMarketCount();
        address marketAddr;
        address ERC721_LpAddr;
        uint256 totalOwned;
        uint256 ID;

        // For all markets
        for(uint256 i = 0 ; i < marketCount ; i++) {
            marketAddr = IMain(_MAIN).getIdToMarket(i);
            ERC721_LpAddr = IMarketPool(marketAddr).getERC721_LP();
            totalOwned = IERC721x(ERC721_LpAddr).balanceOf(msg.sender);

            // For all Ids owned by user
            for(uint256 ii = 0 ; ii < totalOwned ; ii++) {
                ID = IERC721x(ERC721_LpAddr).tokenOfOwnerByIndex(msg.sender, ii);

                // Get rewards
                collateralPool.claimRewards(0, ID);
            }
            
        }

    }

    function claimAllAutoReplaceRewards() public {
        IAutoReplacer AutoReplacer = IAutoReplacer(_AUTOREPLACER);
        address ERC721_AutoReplaceAddr = AutoReplacer.getERC721_AutoReplace();
        uint256 totalOwned = IERC721x(ERC721_AutoReplaceAddr).balanceOf(msg.sender);
        uint256 ID;

        // For all Ids owned by user
        for(uint256 i = 0 ; i < totalOwned ; i++) {
            ID = IERC721x(ERC721_AutoReplaceAddr).tokenOfOwnerByIndex(msg.sender, i);
            AutoReplacer.claimRewards(ID);
        }

    }

    function claimAllRewards() public {
        claimAllNonAutoReplaceRewards();
        claimAllAutoReplaceRewards();
    }

}