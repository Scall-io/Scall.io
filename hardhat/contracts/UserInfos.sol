// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interfaces/IMain.sol";
import "./interfaces/ICollateralPool.sol";
import "./interfaces/IMarketPool.sol";
import "./interfaces/IERC20x.sol";
import "./interfaces/IERC721x.sol";

contract UserInfos {

    address private _MAIN;
    
    constructor(address _main) {
        _MAIN = _main;
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
        uint256 marketCount = IMain(_MAIN).getMarketCount();
        address marketAddr;
        address ERC721_LpAddr;
        uint256 totalOwned;
        uint256 ID;
        uint256 rewards;

        // For all markets
        for(uint256 i = 0 ; i < marketCount ; i++) {
            marketAddr = IMain(_MAIN).getIdToMarket(i);
            ERC721_LpAddr = IMarketPool(marketAddr).getERC721_LP();
            totalOwned = IERC721x(ERC721_LpAddr).balanceOf(_lp);

            // For all Ids
            for(uint256 ii = 0 ; ii < totalOwned ; ii++) {
                ID = IERC721x(ERC721_LpAddr).tokenOfOwnerByIndex(_lp, ii);

                // Get rewards
                rewards += IMarketPool(marketAddr).getRewards(ID);
            }
            
        }

        return rewards;
    }

    function getTotalOpenInterestForLP(address _lp) public view returns(uint256) {
        uint256 marketCount = IMain(_MAIN).getMarketCount();
        address marketAddr;
        address ERC721_LpAddr;
        uint256 totalOwned;
        uint256 ID;
        uint256 openInterest;
        IMarketPool.LpInfos memory thisLP;


        // For all markets
        for(uint256 i = 0 ; i < marketCount ; i++) {
            marketAddr = IMain(_MAIN).getIdToMarket(i);
            ERC721_LpAddr = IMarketPool(marketAddr).getERC721_LP();
            totalOwned = IERC721x(ERC721_LpAddr).balanceOf(_lp);

            // For all Ids
            for(uint256 ii = 0 ; ii < totalOwned ; ii++) {
                ID = IERC721x(ERC721_LpAddr).tokenOfOwnerByIndex(_lp, ii);
                thisLP = IMarketPool(marketAddr).getLpInfos(ID);

                // Get Open Interest
                if (thisLP.isCall) {
                    openInterest += (thisLP.strike * thisLP.amount) / 1e18;
                } else {
                    openInterest += thisLP.amount;
                }
            }
            
        }

        return openInterest;
    }

    function getEstimatedYearlyEarningsForLP(address _lp) public view returns(uint256) {
        uint256 marketCount = IMain(_MAIN).getMarketCount();
        address marketAddr;
        address ERC721_LpAddr;
        uint256 totalOwned;
        uint256 ID;
        uint256 lpProportion;
        uint256 estimatedYearlyEarnings;
        IMarketPool.LpInfos memory thisLP;
        IMarketPool.StrikeInfos memory thisStrike;

        // For all markets
        for(uint256 i = 0 ; i < marketCount ; i++) {
            marketAddr = IMain(_MAIN).getIdToMarket(i);
            ERC721_LpAddr = IMarketPool(marketAddr).getERC721_LP();
            totalOwned = IERC721x(ERC721_LpAddr).balanceOf(_lp);

            // For all Ids
            for(uint256 ii = 0 ; ii < totalOwned ; ii++) {
                ID = IERC721x(ERC721_LpAddr).tokenOfOwnerByIndex(_lp, ii);
                thisLP = IMarketPool(marketAddr).getLpInfos(ID);
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

    function GetUserLps(address _user) public view returns(UserLp[] memory) {
        uint256 marketCount = IMain(_MAIN).getMarketCount();

        // First pass: count how many LPs the user has
        uint256 totalLps = 0;
        for (uint256 x = 0; x < marketCount; x++) {
            IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(x));
            IERC721x ERC721_LP = IERC721x(marketPool.getERC721_LP());
            totalLps += ERC721_LP.balanceOf(_user);
        }

        UserLp[] memory userLpList = new UserLp[](totalLps);
        uint256 lpIndex = 0;

        // For all markets
        for(uint256 i = 0 ; i < marketCount ; i++) {
            IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(i));
            IERC721x ERC721_LP = IERC721x(marketPool.getERC721_LP());
            uint256 balanceOfUser = ERC721_LP.balanceOf(_user);
            uint256 currentPrice = getMarketAssetPrice(i);

            // For all user's lp
            for (uint256 ii = 0; ii < balanceOfUser; ii++) {
                uint256 ID = ERC721_LP.tokenOfOwnerByIndex(_user, ii);
                IMarketPool.LpInfos memory userLpInfos = marketPool.getLpInfos(ID);

                (uint256 withdrawableTokenA, uint256 withdrawableTokenB) = GetWithdrawableForLPForMaket(i, ID);

                bool isITM;
                uint256 value;

                // In-The-Money (ITM) calculation inline
                if (userLpInfos.isCall) {
                    isITM = currentPrice > userLpInfos.strike;
                    value = isITM ? (userLpInfos.amount * userLpInfos.strike) / 1e18 : userLpInfos.amount;
                } else {
                    isITM = currentPrice <= userLpInfos.strike;
                    value = isITM ? (userLpInfos.amount * 1e18) / userLpInfos.strike : userLpInfos.amount;
                }

                userLpList[lpIndex] = UserLp({
                    index: i,
                    ID: ID,
                    isCall: userLpInfos.isCall,
                    strike: userLpInfos.strike,
                    amount: userLpInfos.amount,
                    start: userLpInfos.start,
                    lastClaim: userLpInfos.lastClaim,
                    isITM: isITM,
                    value: value,
                    withdrawableTokenA: withdrawableTokenA,
                    withdrawableTokenB: withdrawableTokenB
                });

                lpIndex++;
            }
        }

        return userLpList;
    }

    struct UserContract {
        uint256 ID;
        bool isCall;
        uint256 strike;
        uint256 amount;
        uint256 rent;
        uint256 start;
        uint256 spent;
        bool isITM;
        uint256 earnings;    
    }

    function GetUserContractsForMarket(uint256 _index, address _user) public view returns(UserContract[] memory) {
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));
        IERC721x ERC721_Contract = IERC721x(marketPool.getERC721_Contract());
        uint256 balanceOfUser = ERC721_Contract.balanceOf(_user);
        uint256 currentPrice = getMarketAssetPrice(_index);

        UserContract[] memory userContractList = new UserContract[](balanceOfUser);

        for (uint256 i = 0; i < balanceOfUser; i++) {
            uint256 ID = ERC721_Contract.tokenOfOwnerByIndex(_user, i);
            IMarketPool.ContractInfos memory userContractInfos = marketPool.getContractInfos(ID);

            uint256 spent = userContractInfos.rent * (block.timestamp - userContractInfos.start);
            bool isITM;
            uint256 earnings; 

            // In-The-Money (ITM) calculation inline
            if (userContractInfos.isCall) {
                isITM = currentPrice > userContractInfos.strike;
                earnings = isITM ? ((currentPrice - userContractInfos.strike) * userContractInfos.amount) / 1e18 : 0;
            } else {
                isITM = currentPrice <= userContractInfos.strike;
                earnings = isITM ? (userContractInfos.strike - currentPrice) * ((userContractInfos.amount * 1e18) / userContractInfos.strike) / 1e18 : 0;
            }

            userContractList[i] = UserContract({
                ID: ID,
                isCall: userContractInfos.isCall,
                strike: userContractInfos.strike,
                amount: userContractInfos.amount,
                rent: userContractInfos.rent,
                start: userContractInfos.start,
                spent: spent,
                isITM: isITM,
                earnings: earnings
            });
        }

        return userContractList;
    }


    function GetUserLpInfosListForMarket(uint256 _index, address _user) public view returns(IMarketPool.LpInfos[] memory) {
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));
        IERC721x ERC721_LP = IERC721x(marketPool.getERC721_LP());
        uint256 balanceOfUser = ERC721_LP.balanceOf(_user);
        uint256 ID;
        IMarketPool.LpInfos[] memory userLpList = new IMarketPool.LpInfos[](balanceOfUser);

        
        for(uint256 i ; i < balanceOfUser ; i++) {
            ID = ERC721_LP.tokenOfOwnerByIndex(_user, i);
            userLpList[i] = marketPool.getLpInfos(ID);
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
