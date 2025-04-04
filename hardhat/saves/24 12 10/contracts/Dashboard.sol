// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "./interfaces/IMain.sol";
import "./interfaces/ICollateralPool.sol";
import "./interfaces/IMarketPool.sol";
import "./interfaces/IERC20x.sol";
import "./interfaces/IERC721x.sol";

import "hardhat/console.sol";

contract Dashboard {

    constructor() {

    }

    struct LiquidationDetails {
        address user;
        uint256 rewards;
    }

    function getAvailableLiquidations() public view returns(LiquidationDetails[] memory) {
        /*
        //Pour tous les User, si leur balance est inférieur à x seconds de fees, alors liquidation possible
        uint256 liqThresh = IMain(_MAIN).getLiquidationThreshold();
        uint256 liqPen = IMain(_MAIN).getLiquidationPenalty();
        uint256 _count;
        uint256 count;

        LiquidationDetails[] memory _liqDetails;
        LiquidationDetails[] memory liqDetails;
        LiquidationDetails[] memory _allLiqDetails;
        LiquidationDetails[] memory allLiqDetails;
        address[] memory users;
        uint256 userRent;
        uint256 userBalance;
        uint256 balanceNeeded;
        uint256 userPenalty;

        for (uint256 i ; i < IMain(_MAIN).getMarketCount() ; i++) {
            
            users = IERC721x(IMarketPool(IMain(_MAIN).getIdToMarket(i)).getERC721_Contract()).getOwners();
            _liqDetails = new LiquidationDetails[](users.length);

            for (uint256 ii ; ii < users.length ; ii++) {
                userRent = getUserRent(users[ii]);
                userBalance = balanceOf(users[ii]);
                balanceNeeded = userRent * liqThresh;
                if (balanceNeeded > userBalance) {
                    userPenalty = (userBalance * liqPen) / 1e18;
                    _liqDetails[_count] = LiquidationDetails(users[ii], userPenalty);
                    _count++;
                }            
            }

            //Remove clones
            liqDetails = new LiquidationDetails[](_count);
            for(uint256 iii ; iii < _count ; iii++) {
                liqDetails[iii] = _liqDetails[iii];
            }

            //Add liqDetails of this market to the total lsit
            allLiqDetails = new LiquidationDetails[](count+_count);
            for(uint256 iiii ; iiii < count ; iiii++) {
                allLiqDetails[iiii] = _allLiqDetails[iiii];
            }
            for(uint256 iiiii = count ; iiiii < count+_count ; iiiii++) {
                allLiqDetails[iiiii] = liqDetails[iiiii];
            }

            _allLiqDetails = allLiqDetails;

            count = count+_count;
        }
 
        return allLiqDetails;
        */
    }

    function getMarketFees(uint256 _index) public view returns (uint256) {
        /*
        //For this market
        address ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_Contract();
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        uint256 currentTime = block.timestamp;
        uint256 fees;

        //For all actives options, add all fees
        for(uint256 i ; i < IERC721x(ERC721_Contract).totalSupply() ; i++) {
            ID = IERC721x(ERC721_Contract).tokenByIndex(i);
            contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getContractInfos(ID);

            //If the option is younger than lastUpdate then "time = currentTime - start", else "time = currentTime - last update"
            if (contractInfos.start > lastUpdate) {
                fees += contractInfos.rent * (currentTime - contractInfos.start);
            } else {
                fees += contractInfos.rent * (currentTime - lastUpdate);
            }
        }

        return fees;
        */
    }

    function getRentPerStrikeForMarket(uint256 strike, uint256 _index) public view returns(uint256) {
        /*
        //For all lps in this market, if they have same strike, then cumulate rent

        address ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_Contract();
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        uint256 rent;

        //For all lps
        for(uint256 i ; i < IERC721x(ERC721_Contract).totalSupply() ; i++) {
            ID = IERC721x(ERC721_Contract).tokenByIndex(i);
            contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getContractInfos(ID);


            //if they have same strike
            if (contractInfos.strike == strike) {
                //Cumulate rent
                rent += contractInfos.rent;
            }             
        }

        return rent;
        */
    }
    
}
