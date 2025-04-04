// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interfaces/IMain.sol";
import "./interfaces/IMarketPool.sol";
import "./interfaces/IAutoReplacer.sol";
import "./interfaces/IERC721x.sol";

contract AutoReplacerInfos {

    address private _MAIN;
    address private _AUTOREPLACER;
    
    constructor(address _main, address _autoReplacer) {
        _MAIN = _main;
        _AUTOREPLACER = _autoReplacer;
    }

    function isPartOf(uint256 _x, uint256[] memory _array) public pure returns(bool) {
        for(uint256 i ; i < _array.length ; i++) {
            if (_x == _array[i]) {
                return true;
            }
        }
        return false;
    }

    function getMarketAssetPrice(uint256 _index) public view returns(uint256) {
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));
        return marketPool.getPrice();
    }

    function getTotalRewardsForLP(address _lp) public view returns(uint256) {
        address ERC721_AutoReplaceAddr = IAutoReplacer(_AUTOREPLACER).getERC721_AutoReplace();
        uint256 totalOwned = IERC721x(ERC721_AutoReplaceAddr).balanceOf(_lp);

        uint256 replaceID;
        IAutoReplacer.AutoReplaceInfos memory autoReplaceInfos;
        address marketAddr;

        uint256 rewards;

        // For all lp's replacerID
        for(uint256 i = 0 ; i < totalOwned ; i++) {

            // Get Infos
            replaceID = IERC721x(ERC721_AutoReplaceAddr).tokenOfOwnerByIndex(_lp, i);
            autoReplaceInfos = IAutoReplacer(_AUTOREPLACER).getAutoReplaceInfos(replaceID);
            marketAddr = IMain(_MAIN).getIdToMarket(autoReplaceInfos.index);
            
            // Get Rewards
            rewards += IMarketPool(marketAddr).getRewards(autoReplaceInfos.id);
            
        }

        return rewards;
    }

    function getTotalOpenInterestForLP(address _lp) public view returns(uint256) {
        address ERC721_AutoReplaceAddr = IAutoReplacer(_AUTOREPLACER).getERC721_AutoReplace();
        uint256 totalOwned = IERC721x(ERC721_AutoReplaceAddr).balanceOf(_lp);

        uint256 replaceID;
        IAutoReplacer.AutoReplaceInfos memory autoReplaceInfos;
        address marketAddr;
        IMarketPool.LpInfos memory thisLP;

        uint256 openInterest;


        // For all lp's replacerID
        for(uint256 i = 0 ; i < totalOwned ; i++) {

            // Get Infos
            replaceID = IERC721x(ERC721_AutoReplaceAddr).tokenOfOwnerByIndex(_lp, i);
            autoReplaceInfos = IAutoReplacer(_AUTOREPLACER).getAutoReplaceInfos(replaceID);
            marketAddr = IMain(_MAIN).getIdToMarket(autoReplaceInfos.index);
            thisLP = IMarketPool(marketAddr).getLpInfos(autoReplaceInfos.id);
            
            // Get Open Interest
            if (thisLP.isCall) {
                openInterest += (thisLP.strike * thisLP.amount) / 1e18;
            } else {
                openInterest += thisLP.amount;
            }
            
        }

        return openInterest;
    }

    function getEstimatedYearlyEarningsForLP(address _lp) public view returns(uint256) {
        address ERC721_AutoReplaceAddr = IAutoReplacer(_AUTOREPLACER).getERC721_AutoReplace();
        uint256 totalOwned = IERC721x(ERC721_AutoReplaceAddr).balanceOf(_lp);

        uint256 replaceID;
        IAutoReplacer.AutoReplaceInfos memory autoReplaceInfos;
        address marketAddr;
        uint256 lpProportion;
        IMarketPool.LpInfos memory thisLP;
        IMarketPool.StrikeInfos memory thisStrike;

        uint256 estimatedYearlyEarnings;


        // For all lp's replacerID
        for(uint256 i = 0 ; i < totalOwned ; i++) {

            // Get Infos
            replaceID = IERC721x(ERC721_AutoReplaceAddr).tokenOfOwnerByIndex(_lp, i);
            autoReplaceInfos = IAutoReplacer(_AUTOREPLACER).getAutoReplaceInfos(replaceID);
            marketAddr = IMain(_MAIN).getIdToMarket(autoReplaceInfos.index);
            thisLP = IMarketPool(marketAddr).getLpInfos(autoReplaceInfos.id);
            thisStrike = IMarketPool(marketAddr).getStrikeInfos(thisLP.strike);
            
            // Get Estimated Earnings
            if (thisLP.isCall) {
                lpProportion = (thisLP.amount * 1e18) / thisStrike.callLP;

                // Liquidity Used x LP Proportion x Yield
                estimatedYearlyEarnings += (((((thisStrike.callLU * thisLP.strike) / 1e18) * lpProportion) / 1e18) * IMarketPool(marketAddr).getYield()) / 1e18;
            } else {
                lpProportion = (thisLP.amount * 1e18) / thisStrike.putLP;

                // Liquidity Used x LP Proportion x Yield
                estimatedYearlyEarnings += (((thisStrike.putLU * lpProportion) / 1e18) * IMarketPool(marketAddr).getYield()) / 1e18;
            }
            
        }

        return estimatedYearlyEarnings;
    }

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

    struct UserLp {
        uint256 index;
        uint256 ID;
        bool isCall;
        uint256 strike;
        uint256 amount;
        uint256 start;
        uint256 lastClaim;
        bool isITM;
        uint256 value;
        uint256 withdrawableTokenA;
        uint256 withdrawableTokenB;     
    }

    function GetUserLps(address _lp) public view returns(UserLp[] memory) {
        address ERC721_AutoReplaceAddr = IAutoReplacer(_AUTOREPLACER).getERC721_AutoReplace();
        uint256 totalOwned = IERC721x(ERC721_AutoReplaceAddr).balanceOf(_lp);

        uint256 replaceID;
        IAutoReplacer.AutoReplaceInfos memory autoReplaceInfos;
        address marketAddr;
        IMarketPool.LpInfos memory thisLP;
        IMarketPool.StrikeInfos memory thisStrike;
        uint256 currentPrice;

        UserLp[] memory userLpList = new UserLp[](totalOwned);


        // For all lp's replacerID
        for(uint256 i = 0 ; i < totalOwned ; i++) {

            // Get Infos
            replaceID = IERC721x(ERC721_AutoReplaceAddr).tokenOfOwnerByIndex(_lp, i);
            autoReplaceInfos = IAutoReplacer(_AUTOREPLACER).getAutoReplaceInfos(replaceID);
            marketAddr = IMain(_MAIN).getIdToMarket(autoReplaceInfos.index);
            thisLP = IMarketPool(marketAddr).getLpInfos(autoReplaceInfos.id);
            thisStrike = IMarketPool(marketAddr).getStrikeInfos(thisLP.strike);
            currentPrice = getMarketAssetPrice(autoReplaceInfos.index);
            
            (uint256 withdrawableTokenA, uint256 withdrawableTokenB) = GetWithdrawableForLPForMaket(autoReplaceInfos.index, autoReplaceInfos.id);

            bool isITM;
            uint256 value;

            // In-The-Money (ITM) calculation inline
            if (thisLP.isCall) {
                isITM = currentPrice > thisLP.strike;
                value = isITM ? (thisLP.amount * thisLP.strike) / 1e18 : thisLP.amount;
            } else {
                isITM = currentPrice <= thisLP.strike;
                value = isITM ? (thisLP.amount * 1e18) / thisLP.strike : thisLP.amount;
            }

            userLpList[i] = UserLp({
                index: autoReplaceInfos.index,
                ID: autoReplaceInfos.id,
                isCall: thisLP.isCall,
                strike: thisLP.strike,
                amount: thisLP.amount,
                start: thisLP.start,
                lastClaim: thisLP.lastClaim,
                isITM: isITM,
                value: value,
                withdrawableTokenA: withdrawableTokenA,
                withdrawableTokenB: withdrawableTokenB
            });
            
        }

        return userLpList;
    }

    function GetUserLpInfosListForMarket(uint256 _index, address _user) public view returns(IMarketPool.LpInfos[] memory) {
        address ERC721_AutoReplaceAddr = IAutoReplacer(_AUTOREPLACER).getERC721_AutoReplace();
        uint256 totalOwned = IERC721x(ERC721_AutoReplaceAddr).balanceOf(_user);
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));

        uint256 replaceID;
        IAutoReplacer.AutoReplaceInfos memory autoReplaceInfos;
        IMarketPool.LpInfos[] memory userLpList = new IMarketPool.LpInfos[](totalOwned);

        // For all lp's replacerID
        for(uint256 i ; i < totalOwned ; i++) {

            // Get Infos
            replaceID = IERC721x(ERC721_AutoReplaceAddr).tokenOfOwnerByIndex(_user, i);
            autoReplaceInfos = IAutoReplacer(_AUTOREPLACER).getAutoReplaceInfos(replaceID);

            // Add LP Infos
            userLpList[i] = marketPool.getLpInfos(autoReplaceInfos.id);
        }

        return userLpList;
    }

    function GetUserLpAmountsForStrikeForMarket(uint256 _index, address _user, uint256 _strike) public view returns(uint256[] memory) {
        IMarketPool.LpInfos[] memory userLpList = GetUserLpInfosListForMarket(_index, _user);
        uint256[] memory userLpAmounts = new uint256[](2);

        for(uint256 i = 0 ; i < userLpList.length ; i++) {

            if(userLpList[i].strike == _strike) {

                if(userLpList[i].isCall) {
                    userLpAmounts[0] += userLpList[i].amount;
                } else {
                    userLpAmounts[1] += userLpList[i].amount;
                }

            }

        }

        return userLpAmounts;       
    }

    function GetUserLpStrikesForMarket(uint256 _index, address _user) public view returns(uint256[] memory) {
        IMarketPool.LpInfos[] memory userLpList = GetUserLpInfosListForMarket(_index, _user);
        uint256[] memory _userLpStrikes = new uint256[](userLpList.length);
        uint256 count;

        for(uint256 i = 0 ; i < userLpList.length ; i++) {

            if(!isPartOf(userLpList[i].strike, _userLpStrikes)) {
                _userLpStrikes[count] = userLpList[i].strike;
                count++;
            }

        }

        // Remove unused indexes
        uint256[] memory userLpStrikes = new uint256[](count);
        for(uint256 ii ; ii < count ; ii++) {
            userLpStrikes[ii] = _userLpStrikes[ii];
        }

        return userLpStrikes;       
    }

    struct UserLpInfos {
        uint256 callProvided; // Amount of liquidity provided
        uint256 callUsed; // Amount of liquidity under use
        uint256 callUsedITM; // Amount of liquidity under use in profit
        uint256 callAvailable; // Amount of withdrawable liquidity
        uint256 callReturned; // Amount of liquidity returned
        uint256 putProvided;
        uint256 putUsed;
        uint256 putUsedITM;
        uint256 putAvailable;
        uint256 putReturned;
    }

    function getUserLpInfosForMarket(uint256 _index, address _user) public view returns(UserLpInfos memory) {
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));
        uint256[] memory userLpStrikes = GetUserLpStrikesForMarket(_index, _user);
        uint256[] memory strikesAmount;
        UserLpInfos memory lpUserInfos;
        IMarketPool.StrikeInfos memory strikeInfos;
        uint256 price = marketPool.getPrice();


        for(uint256 i = 0 ; i < userLpStrikes.length ; i++) {
            strikesAmount = GetUserLpAmountsForStrikeForMarket(_index, _user, userLpStrikes[i]);
            lpUserInfos.callProvided += strikesAmount[0];
            lpUserInfos.putProvided += strikesAmount[1];

            strikeInfos = marketPool.getStrikeInfos(userLpStrikes[i]);

            // Calculate withdrawable returnned liquidity
            if (strikeInfos.callLR >= (strikesAmount[0]*userLpStrikes[i])/1e18) {
                lpUserInfos.callReturned += (strikesAmount[0]*userLpStrikes[i])/1e18;
            } else {
                lpUserInfos.callReturned += strikeInfos.callLR;
            }

            if (strikeInfos.putLR >= (strikesAmount[1]*1e18)/userLpStrikes[i]) {
                lpUserInfos.putReturned += (strikesAmount[1]*1e18)/userLpStrikes[i];
            } else {
                lpUserInfos.putReturned += strikeInfos.putLR;
            }

            // Calculate withdrawable liquidity
            if (strikeInfos.callLP - strikeInfos.callLU >= strikesAmount[0]) {
                lpUserInfos.callAvailable += strikesAmount[0];
            } else {
                lpUserInfos.callAvailable += strikeInfos.callLP - strikeInfos.callLU;
            }

            if (strikeInfos.putLP - strikeInfos.putLU >= strikesAmount[1]) {
                lpUserInfos.putAvailable += strikesAmount[1];
            } else {
                lpUserInfos.putAvailable += strikeInfos.putLP - strikeInfos.putLU;
            }

            // Calculate used liquidity
            if (strikeInfos.callLU >= strikesAmount[0]) {
                lpUserInfos.callUsed += strikesAmount[0];
            } else {
                lpUserInfos.callUsed += strikeInfos.callLU;
            }

            if (strikeInfos.putLU >= strikesAmount[1]) {
                lpUserInfos.putUsed += strikesAmount[1];
            } else {
                lpUserInfos.putUsed += strikeInfos.putLU;
            }

            // If price superior to Strike
            if(price >= userLpStrikes[i]) {

                // Call in Profit is 
                if (strikeInfos.callLU >= strikesAmount[0]) {
                    lpUserInfos.callUsedITM += strikesAmount[0];
                } else {
                    lpUserInfos.callUsedITM += strikeInfos.callLU;
                }

            } else {
                if (strikeInfos.putLU >= strikesAmount[1]) {
                    lpUserInfos.putUsedITM += strikesAmount[1];
                } else {
                    lpUserInfos.putUsedITM += strikeInfos.putLU;
                }
            }
            
        }

        return lpUserInfos;

    }
    

}
