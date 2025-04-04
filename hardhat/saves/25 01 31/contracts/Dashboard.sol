// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "./interfaces/IMain.sol";
import "./interfaces/ICollateralPool.sol";
import "./interfaces/IMarketPool.sol";
import "./interfaces/IERC20x.sol";
import "./interfaces/IERC721x.sol";

import "hardhat/console.sol";

contract Dashboard {

    address private _MAIN;
    
    constructor(address _main) {
        _MAIN = _main;
    }

    function isPartOf(address _x, address[] memory _array) public pure returns(bool) {
        for(uint256 i ; i < _array.length ; i++) {
            if (_x == _array[i]) {
                return true;
            }
        }
        return false;
    }

    function isPartOf(uint256 _x, uint256[] memory _array) public pure returns(bool) {
        for(uint256 i ; i < _array.length ; i++) {
            if (_x == _array[i]) {
                return true;
            }
        }
        return false;
    }

    function getMarketOpenInterest(uint256 _index) public view returns(uint256[2] memory) {

        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));
        address ERC721_Contrat = marketPool.getERC721_Contract();
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        uint256 callOI;
        uint256 putOI;

        //For all open contracts => add their amount
        for(uint256 i ; i < IERC721x(ERC721_Contrat).totalSupply() ; i++) {
            ID = IERC721x(ERC721_Contrat).tokenByIndex(i);
            contractInfos = marketPool.getContractInfos(ID);
            if (contractInfos.isCall) {
                callOI += contractInfos.amount;
            } else {
                putOI += contractInfos.amount;
            }
        }

        return [callOI, putOI];
    }

    function getMarketLiquidityProvided(uint256 _index) public view returns(uint256[2] memory) {

        // Get Infos
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));
        address ERC721_LP = marketPool.getERC721_LP();
        uint256 ID;
        IMarketPool.LpInfos memory lpInfos;
        uint256 callLP;
        uint256 putLP;

        //For all LPs 
        for(uint256 i ; i < IERC721x(ERC721_LP).totalSupply() ; i++) {
            ID = IERC721x(ERC721_LP).tokenByIndex(i);
            lpInfos = marketPool.getLpInfos(ID);

            // Add their amount
            if (lpInfos.isCall) {
                callLP += lpInfos.amount;
            } else {
                putLP += lpInfos.amount;
            }
        }

        return [callLP, putLP];
    }

    function getMarketActiveStrikes(uint256 _index) public view returns(uint256[] memory) {

        // Get Infos
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));
        address ERC721_LP = marketPool.getERC721_LP();
        uint256 ID;
        IMarketPool.LpInfos memory lpInfos;
        IERC721x erc721_lp = IERC721x(ERC721_LP);
        uint256[] memory _activeStrikes = new uint256[](erc721_lp.totalSupply());
        uint256 count;

        // For all Lps
        for(uint256 i = 0 ; i < _activeStrikes.length ; i++) {
            ID = IERC721x(ERC721_LP).tokenByIndex(i);
            lpInfos = marketPool.getLpInfos(ID);

            // Add strike to list if not already in it
            if (!isPartOf(lpInfos.strike, _activeStrikes)) {
                _activeStrikes[count] = lpInfos.strike;
                count++;
            }
            
        }

        // Remove unused indexes
        uint256[] memory activeStrikes = new uint256[](count);
        for(uint256 ii ; ii < count ; ii++) {
            activeStrikes[ii] = _activeStrikes[ii];
        }

        return activeStrikes;        
    }

    struct MpBalanceDetail {
        uint256 tokenA;
        uint256 tokenAProvided;
        uint256 tokenAFromPut;
        uint256 tokenB;
        uint256 tokenBProvided;
        uint256 tokenBFromCall;
    }

    function getMarketBalanceDetail(uint256 _index) public view returns(MpBalanceDetail memory) {
        address marketPoolAddr = IMain(_MAIN).getIdToMarket(_index);
        IMarketPool marketPool = IMarketPool(marketPoolAddr);
        IMarketPool.StrikeInfos memory strikeInfos;
        MpBalanceDetail memory balanceDetail;
        balanceDetail.tokenA = IERC20x(marketPool.getTokenA()).balanceOf(marketPoolAddr);
        balanceDetail.tokenB = IERC20x(marketPool.getTokenB()).balanceOf(marketPoolAddr);

        uint256[] memory activeStrikes = getMarketActiveStrikes(_index);

        //For all active strikes, get TokenReturned, and provided will be provided - return
        for(uint256 i = 0 ; i < activeStrikes.length ; i++) {
            strikeInfos = marketPool.getStrikeInfos(activeStrikes[i]);
            balanceDetail.tokenAFromPut += strikeInfos.putLR;
            balanceDetail.tokenBFromCall += strikeInfos.callLR;
            balanceDetail.tokenAProvided += strikeInfos.callLP - (strikeInfos.callLR*1e18)/activeStrikes[i];
            balanceDetail.tokenBProvided += strikeInfos.putLP - (strikeInfos.putLR*activeStrikes[i])/1e18;
        }

        return balanceDetail;
    }

    struct CpBalanceDetail {
        uint256 CollateralToken; //Should be UsersBalance + LpsBalance + Deposits that are not under use
        uint256 UsersBalance;
        uint256 LpsBalance;

    }

    function getUsersCount() public view returns(uint256) {
        uint256 marketCount = IMain(_MAIN).getMarketCount();
        address marketAddr;
        address ERC721_ContractAddr;
        uint256 count;

        // For all ERC721_Contract
        for(uint256 i = 0 ; i < marketCount ; i++) {
            marketAddr = IMain(_MAIN).getIdToMarket(i);
            ERC721_ContractAddr = IMarketPool(marketAddr).getERC721_Contract();

            // Add all their user count
            address[] memory _marketUsers = IERC721x(ERC721_ContractAddr).getOwners();
            count += _marketUsers.length;
        }

        return count;

    }

    function getAllUsers() public view returns(address[] memory) {
        uint256 marketCount = IMain(_MAIN).getMarketCount();
        address marketAddr;
        address ERC721_ContractAddr;
        uint256 _count = getUsersCount();
        address[] memory _users = new address[](_count);
        uint256 count;

        // For all ERC721_Contract
        for(uint256 i = 0 ; i < marketCount ; i++) {
            marketAddr = IMain(_MAIN).getIdToMarket(i);
            ERC721_ContractAddr = IMarketPool(marketAddr).getERC721_Contract();

            // Add their user address if not already included
            address[] memory marketUsers = IERC721x(ERC721_ContractAddr).getOwners();
            for(uint256 ii = 0 ; ii < marketUsers.length ; ii++) {

                if(!isPartOf(marketUsers[ii], _users)) {
                    _users[count] = marketUsers[ii];
                    count++;
                }

            }
            
        }

        // Remove unused indexes
        address[] memory users = new address[](count);
        for(uint256 iii ; iii < count ; iii++) {
            users[iii] = _users[iii];
        }

        return users;
    }

    function getLpsCount() public view returns(uint256) {
        uint256 marketCount = IMain(_MAIN).getMarketCount();
        address marketAddr;
        address ERC721_LPAddr;
        uint256 count;

        // For all ERC721_Contract
        for(uint256 i = 0 ; i < marketCount ; i++) {
            marketAddr = IMain(_MAIN).getIdToMarket(i);
            ERC721_LPAddr = IMarketPool(marketAddr).getERC721_LP();

            // Add all their user count
            address[] memory _marketUsers = IERC721x(ERC721_LPAddr).getOwners();
            count += _marketUsers.length;
        }

        return count;

    }

    function getAllLps() public view returns(address[] memory) {
        uint256 marketCount = IMain(_MAIN).getMarketCount();
        address marketAddr;
        address ERC721_LpAddr;
        uint256 _count = getLpsCount();
        address[] memory _lps = new address[](_count);
        uint256 count;

        // For all ERC721_Contract
        for(uint256 i = 0 ; i < marketCount ; i++) {
            marketAddr = IMain(_MAIN).getIdToMarket(i);
            ERC721_LpAddr = IMarketPool(marketAddr).getERC721_LP();

            // Add their user address if not already included
            address[] memory marketLps = IERC721x(ERC721_LpAddr).getOwners();
            for(uint256 ii = 0 ; ii < marketLps.length ; ii++) {

                if(!isPartOf(marketLps[ii], _lps)) {
                    _lps[count] = marketLps[ii];
                    count++;
                }

            }
            
        }

        // Remove unused indexes
        address[] memory lps = new address[](count);
        for(uint256 iii ; iii < count ; iii++) {
            lps[iii] = _lps[iii];
        }

        return lps;
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

    function getCollateralPoolBalanceDetail() public view returns(CpBalanceDetail memory) {
        CpBalanceDetail memory balanceDetail;
        balanceDetail.CollateralToken = IERC20x(IMain(_MAIN).getCollateralToken()).balanceOf(IMain(_MAIN).getCollateralPool());

        // Calculate Users Balance
        // Pour tous les Users, add their balance
        address[] memory users = getAllUsers();
        for(uint256 i = 0 ; i < users.length ; i++) {
            balanceDetail.UsersBalance += ICollateralPool(IMain(_MAIN).getCollateralPool()).balanceOf(users[i]);
        }

        // Calculate Lps Balance
        // Pour tous les Lps, add their rewards + fees
        address[] memory lps = getAllLps();
        for(uint256 ii = 0 ; ii < lps.length ; ii++) {
            balanceDetail.LpsBalance += getTotalRewardsForLP(lps[ii]);
        }

        return balanceDetail;
        
    }

    function getMarketAvailableLiquidation(uint256 _index) public view returns(address[] memory) {
        
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));
        ICollateralPool collateralPool = ICollateralPool(IMain(_MAIN).getCollateralPool());
        address[] memory users = IERC721x(marketPool.getERC721_Contract()).getOwners();
        address[] memory _usersToLiquidate = new address[](users.length);
        uint256 count;


        //For all Users, if liquidation needed => add to result
        for(uint256 i ; i < users.length ; i++) {
            if (collateralPool.needLiquidation(users[i])) {
                if (!isPartOf(users[i], _usersToLiquidate)) {
                    _usersToLiquidate[count] = users[i];
                    count++;
                }
            }
        }

        // Remove unused indexes
        address[] memory usersToLiquidate = new address[](count);
        for(uint256 ii ; ii < count ; ii++) {
            usersToLiquidate[ii] = _usersToLiquidate[ii];
        }

        return usersToLiquidate;
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
