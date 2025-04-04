// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interfaces/IMain.sol";
import "./interfaces/ICollateralPool.sol";
import "./interfaces/IMarketPool.sol";
import "./interfaces/IERC20x.sol";
import "./interfaces/IERC721x.sol";

contract ProtocolInfos {

    address private _MAIN;
    
    constructor(address _main) {
        _MAIN = _main;
    }

    function tokenATo18(uint256 _index, uint256 _amount) private view returns(uint256) {
        return (_amount * 1e18)/10**IERC20x(IMain(_MAIN).getIdToMarketInfos(_index).tokenA).decimals();
    }

    function tokenBTo18(uint256 _amount) private view returns(uint256) {
        return (_amount * 1e18)/10**IMain(_MAIN).getCollateralTokenDecimals();
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

    function getMarketAssetPrice(uint256 _index) public view returns(uint256) {
        IMarketPool marketPool = IMarketPool(IMain(_MAIN).getIdToMarket(_index));
        return marketPool.getPrice();
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
        balanceDetail.tokenA = tokenATo18(_index, IERC20x(marketPool.getTokenA()).balanceOf(marketPoolAddr));
        balanceDetail.tokenB = tokenBTo18(IERC20x(marketPool.getTokenB()).balanceOf(marketPoolAddr));

        uint256[] memory activeStrikes = getMarketActiveStrikes(_index);

        // For all active strikes, get TokenReturned, and provided will be provided - return
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
        uint256 CollateralToken; // Should be UsersBalance + LpsBalance + Sleeping Collateral (users without contract)
        uint256 UsersBalance; // Collateral of users with active contracts
        uint256 LpsBalance; // LPs rewards

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
        balanceDetail.CollateralToken = tokenBTo18(IERC20x(IMain(_MAIN).getCollateralToken()).balanceOf(IMain(_MAIN).getCollateralPool()));

        // Calculate Users Balance
        // Pour tous les Users, add their balance
        address[] memory users = getAllUsers();
        for(uint256 i = 0 ; i < users.length ; i++) {
            balanceDetail.UsersBalance += ICollateralPool(IMain(_MAIN).getCollateralPool()).balanceOf(users[i]);
        }

        // Calculate Lps Balance
        // Pour tous les Lps, add their rewards (including protocol fees))
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

}
