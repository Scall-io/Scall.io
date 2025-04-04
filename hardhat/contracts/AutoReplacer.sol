// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC721_AutoReplace.sol";
import "./interfaces/IMain.sol";
import "./interfaces/IMarketPool.sol";
import "./interfaces/ICollateralPool.sol";
import "./interfaces/IERC721x.sol";
import "./interfaces/IERC20x.sol";
import "./interfaces/IERC721Receiver.sol";

/// @title AutoReplacer - Automatically replace LP option positions
/// @notice This contract allows users to automatically replace their ERC721 option positions with new ones
/// @dev Integrates with Main.sol, MarketPool.sol and ERC721_AutoReplace.sol
contract AutoReplacer is IERC721Receiver {

    address private _MAIN;
    address private _ERC721_AUTOREPLACE;

    /// @notice Constructor to initialize the AutoReplacer contract
    /// @param _main Address of the Main contract
    constructor(address _main) {
        _MAIN = _main;

        ERC721_AutoReplace erc721_autoReplace = new ERC721_AutoReplace(address(this), "AutoReplace", "AutoReplace");
        _ERC721_AUTOREPLACE = address(erc721_autoReplace);
    }

    /// @notice Counter for issued AutoReplace NFTs
    uint256 private _count;

    /// @notice Struct containing metadata for each auto-replaced position
    /// @param index Market index from Main contract
    /// @param id ERC721 LP token ID being replaced
    struct AutoReplaceInfos {
        uint256 index;
        uint256 id;
        uint256 rewards;
    }

    /// @notice Mapping from new AutoReplace token ID to original LP token info
    mapping(uint256 => AutoReplaceInfos) private _autoReplaceIdToInfos;

    /// @notice Returns the address of the deployed ERC721_AutoReplace contract
    /// @return Address of ERC721_AutoReplace
    function getERC721_AutoReplace() external view returns(address) {
        return _ERC721_AUTOREPLACE;
    }

    /// @notice Returns the metadata associated with a specific AutoReplace token ID
    /// @param _replacerID Token ID of the AutoReplace NFT
    /// @return AutoReplaceInfos struct containing original LP token info
    function getAutoReplaceInfos(uint256 _replacerID) external view returns(AutoReplaceInfos memory) {
        return _autoReplaceIdToInfos[_replacerID];
    }

    /// @notice Begins the auto-replacement process for an ERC721 LP token
    /// @dev Transfers the LP NFT to this contract and issues a new AutoReplace NFT
    /// @param _index Index of the market pool in Main.sol
    /// @param _id ID of the original LP ERC721 token to be replaced
    function startAutoReplace(uint256 _index, uint256 _id) public {
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));
        address ERC721_ADDR = marketPool.getERC721_LP();

        require(msg.sender == IERC721x(ERC721_ADDR).ownerOf(_id), "You are not the owner of this ERC721");

        // User sends the original NFT
        IERC721x(ERC721_ADDR).transferFrom(msg.sender, address(this), _id);

        // Update and Save Infos
        AutoReplaceInfos memory newInfos = AutoReplaceInfos(_index, _id, 0);
        _autoReplaceIdToInfos[_count] = newInfos;

        // Send the new NFT
        IERC721x(_ERC721_AUTOREPLACE).mint(msg.sender, _count);

        _count++;
    }

    /// @notice Stops the auto-replacement process for a specific AutoReplace NFT
    /// @dev Burns the AutoReplace NFT and returns the original LP ERC721 token to the user
    /// @param _replacerID The token ID of the AutoReplace NFT to stop
    function stopAutoReplace(uint256 _replacerID) public returns(uint256) {
        AutoReplaceInfos memory thisAutoReplace = _autoReplaceIdToInfos[_replacerID];
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(thisAutoReplace.index));
        address ERC721_ADDR = marketPool.getERC721_LP();

        // Security Check
        require(msg.sender == IERC721x(_ERC721_AUTOREPLACE).ownerOf(_replacerID), "You are not the owner of this ERC721");

        // Claim rewards
        uint256 claimedRewards = claimRewards(_replacerID);

        // Burn the new NFT
        IERC721x(_ERC721_AUTOREPLACE).burn(_replacerID);

        // Send the original NFT
        IERC721x(ERC721_ADDR).transferFrom(address(this), msg.sender, thisAutoReplace.id);

        return claimedRewards;
    }

    /// @notice Replaces an LP position held by this contract with a new one if the strike is no longer optimal
    /// @dev Withdraws the old LP position and redeposits at the optimal interval if fully withdrawable
    /// @param _replacerID The token ID of the AutoReplace NFT linked to the LP position to replace
    function replace(uint256 _replacerID) public {
        AutoReplaceInfos memory thisAutoReplace = _autoReplaceIdToInfos[_replacerID];
        address marketPoolAddr = IMain(_MAIN).getIdToMarket(thisAutoReplace.index);
        IMarketPool marketPool = IMarketPool(marketPoolAddr);
        IMarketPool.LpInfos memory thisLP = marketPool.getLpInfos(thisAutoReplace.id);
        uint256[] memory intervals = marketPool.getIntervals();

        (uint256 withdrawabletokenA, uint256 withdrawabletokenB) = GetWithdrawableForLPForMaket(thisAutoReplace.index, thisAutoReplace.id);
        
        if (thisLP.isCall) {

            // If this LP strike has to be replaced
            if (thisLP.strike != intervals[intervals.length / 2]) {

                if (withdrawabletokenA == thisLP.amount) {
                    // Withdraw the position
                    (uint256 tokenAWithdrawn,, uint256 claimedRewards) = marketPool.withdraw(thisAutoReplace.id);                    

                    // Approve MarketPool to spend tokens
                    IERC20x(marketPool.getTokenA()).approve(marketPoolAddr, tokenAWithdrawn);

                    // Deposit the position at nearer interval
                    uint256 newID = marketPool.deposit(thisLP.isCall, tokenAWithdrawn);
                    
                    // Update AutoReplaceInfos
                    _autoReplaceIdToInfos[_replacerID].rewards += claimedRewards;
                    _autoReplaceIdToInfos[_replacerID].id = newID;
                }

            }

        } else {

            // If this LP strike has to be replaced
            if (thisLP.strike != intervals[0]) {

                if (withdrawabletokenB == thisLP.amount) {
                    // Withdraw the position
                    (, uint256 tokenBWithdrawn, uint256 claimedRewards) = marketPool.withdraw(thisAutoReplace.id);

                    // Approve MarketPool to spend tokens
                    IERC20x(marketPool.getTokenB()).approve(marketPoolAddr, tokenBWithdrawn);

                    // Deposit the position at nearer interval
                    uint256 newID = marketPool.deposit(thisLP.isCall, tokenBWithdrawn);

                    // Update AutoReplaceInfos
                    _autoReplaceIdToInfos[_replacerID].rewards += claimedRewards;
                    _autoReplaceIdToInfos[_replacerID].id = newID;
                }

            }

        }

    }

    /// @notice Iterates over all active AutoReplace NFTs and attempts to replace each associated LP position if necessary
    /// @dev Performs `replace()` logic in batch for all users who started auto-replacement
    function replaceAll() public {
        uint256[] memory activeIds = IERC721x(_ERC721_AUTOREPLACE).getAllTokenIds();

        // For all active Ids
        for (uint256 i = 0; i < activeIds.length; i++) {
            replace(activeIds[i]);
        }
        
    }

    /// @notice Claims all accumulated rewards for a specific AutoReplace NFT
    /// @dev Combines rewards from the current LP position and any residual rewards from the old position
    /// @param _replacerID The ID of the AutoReplace NFT whose rewards are being claimed
    /// @return totalRewards The total amount of rewards claimed and transferred to the NFT owner
    function claimRewards(uint256 _replacerID) public returns(uint256) {

        // Allowed to claim ?
        address idOwner = IERC721x(_ERC721_AUTOREPLACE).ownerOf(_replacerID);
        require(tx.origin == idOwner, "You are not this NFT owner");

        // Rewards
        uint256 actualRewards = ICollateralPool(IMain(_MAIN).getCollateralPool()).claimRewards(_autoReplaceIdToInfos[_replacerID].index, _autoReplaceIdToInfos[_replacerID].id);
        uint256 totalRewards = actualRewards + _autoReplaceIdToInfos[_replacerID].rewards;

        // Update autoReplaceInfos
        _autoReplaceIdToInfos[_replacerID].rewards = 0;

        // Send Rewards to owner
        IERC20x(IMain(_MAIN).getCollateralToken()).transfer(idOwner, totalRewards);

        return totalRewards;
    }

    /// @notice Calculates the withdrawable amounts of tokenA and tokenB for a specific LP position
    /// @dev Determines how much liquidity can be withdrawn based on available funds and strike configuration
    /// @param _index The market index in Main.sol
    /// @param _id The ID of the LP ERC721 token
    /// @return withdrawabletokenA Amount of tokenA the LP can withdraw
    /// @return withdrawabletokenB Amount of tokenB the LP can withdraw
    function GetWithdrawableForLPForMaket(uint256 _index, uint256 _id) public view returns (uint256, uint256) {
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));
        
        // Get Infos
        IMarketPool.LpInfos memory thisLP = marketPool.getLpInfos(_id);
        IMarketPool.StrikeInfos memory strikeInfos = marketPool.getStrikeInfos(thisLP.strike);
        uint256 liquidityReturned;
        uint256 availableFunds;
        uint256 withdrawabletokenA;
        uint256 withdrawabletokenB;

        // Call or Put ?
        if (thisLP.isCall) {

            availableFunds = strikeInfos.callLP - strikeInfos.callLU;

            if (strikeInfos.callLR > 0) {

                liquidityReturned = (strikeInfos.callLR * 1e18)/thisLP.strike;

                // If available funds can't cover LP amount
                if (availableFunds < thisLP.amount) {

                    // Transfers
                    withdrawabletokenB = strikeInfos.callLR;
                    withdrawabletokenA = availableFunds - liquidityReturned;

                } else {

                    if (liquidityReturned >= thisLP.amount ) {

                        // Transfers
                        withdrawabletokenB = (thisLP.amount * thisLP.strike)/1e18;
                        withdrawabletokenA = 0;

                    } else {

                        // Transfers
                        withdrawabletokenB = strikeInfos.callLR;
                        withdrawabletokenA = thisLP.amount - liquidityReturned;

                    }

                }

            } else {

                // If available funds can't cover LP amount
                if (availableFunds < thisLP.amount) {

                    // Transfers
                    withdrawabletokenB = 0;
                    withdrawabletokenA = availableFunds;

                } else {

                    // Transfers
                    withdrawabletokenB = 0;
                    withdrawabletokenA = thisLP.amount;

                }

            }
            

        } else {

            availableFunds = strikeInfos.putLP - strikeInfos.putLU;

            if (strikeInfos.putLR > 0) {

                liquidityReturned = (strikeInfos.putLR * thisLP.strike)/1e18;

                // If available funds can't cover LP amount
                if (availableFunds < thisLP.amount) {

                    // Transfers
                    withdrawabletokenA = strikeInfos.putLR;
                    withdrawabletokenB = availableFunds - liquidityReturned;

                } else {

                    if (liquidityReturned >= thisLP.amount) {

                        // Transfers
                        withdrawabletokenA = (thisLP.amount * 1e18)/thisLP.strike;
                        withdrawabletokenB = 0;

                    } else {

                        // Transfers
                        withdrawabletokenA = strikeInfos.putLR;
                        withdrawabletokenB = thisLP.amount - liquidityReturned;

                    }

                }


            } else {

                // If available funds can't cover LP amount
                if (availableFunds < thisLP.amount) {

                    // Transfers
                    withdrawabletokenA = 0;
                    withdrawabletokenB = availableFunds;

                } else {

                    // Transfers
                    withdrawabletokenA = 0;
                    withdrawabletokenB = thisLP.amount;

                }
            }
        }

        return (withdrawabletokenA, withdrawabletokenB);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        operator; from; tokenId; data;
        return IERC721Receiver.onERC721Received.selector;
    }

}