// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "./interfaces/IMain.sol";
import "./interfaces/IMarketPool.sol";
import "./interfaces/IERC20x.sol";
import "./interfaces/IERC721x.sol";

import "hardhat/console.sol";

contract CollateralPool {

    address private _COLLATERALTOKEN;
    address private _MAIN;

    uint256 public lastUpdate;
    
    constructor(address _collateralToken, address _main) {
        _COLLATERALTOKEN = _collateralToken;
        _MAIN = _main;

        lastUpdate = block.timestamp;
    }

    function getMain() public view returns(address) {
        return _MAIN;
    }

    mapping(address => uint256) private _userCollateral;

    function getRewardsFromUser(address _user) public view returns(uint256) {

        //Initialize Variables
        uint256 rewards;

        //For all markets ERC721_Contracts
        for(uint256 i ; i < IMain(_MAIN).getMarketCount() ; i++) {
            rewards += getRewardsFromUserForMarket(_user, i);            
        }

        return rewards;
    }

    /*
    function getRewardsFromUser(address _user) public view returns(uint256) {

        //Initialize Variables
        address ERC721_Contract;
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        uint256 currentTime = block.timestamp;
        uint256 rewards;

        //For all markets ERC721_Contracts
        for(uint256 i ; i < IMain(_MAIN).getMarketCount() ; i++) {
            ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(i)).getERC721_Contract();

            //For all user's options, add all rents payment since last update
            for(uint256 ii ; ii < IERC721x(ERC721_Contract).balanceOf(_user) ; ii++) {
                ID = IERC721x(ERC721_Contract).tokenOfOwnerByIndex(_user, ii);
                contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(i)).getContractInfos(ID);

                //If the option is younger than lastUpdate then "time = currentTime - start", else "time = currentTime - last update"
                if (contractInfos.start > lastUpdate) {
                    rewards += contractInfos.rent * (currentTime - contractInfos.start);
                } else {
                    rewards += contractInfos.rent * (currentTime - lastUpdate);
                }
            }
        }

        return rewards;
    }
    */

    function getRewardsFromUserForMarket(address _user, uint256 _index) public view returns(uint256) {

        //Initialize Variables
        address ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_Contract();
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        uint256 currentTime = block.timestamp;
        uint256 rewards;

        //For all user's options, add all rents payment since last update
        for(uint256 i ; i < IERC721x(ERC721_Contract).balanceOf(_user) ; i++) {
            ID = IERC721x(ERC721_Contract).tokenOfOwnerByIndex(_user, i);
            contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getContractInfos(ID);

            //If the option is younger than lastUpdate then "time = currentTime - start", else "time = currentTime - last update"
            if (contractInfos.start > lastUpdate) {
                rewards += contractInfos.rent * (currentTime - contractInfos.start);
            } else {
                rewards += contractInfos.rent * (currentTime - lastUpdate);
            }
        }

        return rewards;
    }

    function balanceOf(address _user) public view returns(uint256) {
        uint256 actualFees = getRewardsFromUser(_user);
        return _userCollateral[_user] - actualFees;
    }

    function getUserTotalRent(address _user) public view returns(uint256) {

        address ERC721_Contract;
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        uint256 rent;

        // For all markets ERC721_Contracts
        for(uint256 i ; i < IMain(_MAIN).getMarketCount() ; i++) {
            ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(i)).getERC721_Contract();

            // For all actives user's options, add all rents
            for(uint256 ii ; ii < IERC721x(ERC721_Contract).balanceOf(_user) ; ii++) {
                ID = IERC721x(ERC721_Contract).tokenOfOwnerByIndex(_user, ii);
                contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(i)).getContractInfos(ID);
                rent += contractInfos.rent;
            }
        }

        return rent;
    }

    function depositCollateral(uint256 _amount) public {
        IERC20x(_COLLATERALTOKEN).transferFrom(msg.sender, address(this), _amount);
        _userCollateral[msg.sender] += _amount;
    }

    function withdrawCollateral(uint256 _amount) public {

        uint256 minCollateral = IMain(_MAIN).getMinCollateral();
        uint256 userRent = getUserTotalRent(msg.sender);

        //Il faut que collateral restant soit > à user rend x minCollateral
        require(balanceOf(msg.sender) - _amount >= userRent * minCollateral, "Not enough collateral");

        IERC20x(_COLLATERALTOKEN).transfer(msg.sender, _amount);
        _userCollateral[msg.sender] -= _amount;
    }

    function needLiquidation(address _user) public view returns(bool) {
        uint256 liqThresh = IMain(_MAIN).getLiquidationThreshold();

        //User Infos
        uint256 userRent = getUserTotalRent( _user);
        uint256 userBalance = balanceOf( _user);
        uint256 balanceNeeded = userRent * liqThresh;

        //Returns
        if (balanceNeeded > userBalance) {
            return true;
        } else {
            return false;
        }        
    }

    function canBuyOption(address _user, uint256 _rent) public view returns(bool) {
        uint256 liqThresh = IMain(_MAIN).getLiquidationThreshold();

        //User Infos
        uint256 userNewRent = getUserTotalRent( _user) + _rent;
        uint256 userBalance = balanceOf( _user);
        uint256 balanceNeeded = userNewRent * liqThresh;

        //Returns
        if (balanceNeeded > userBalance) {
            return true;
        } else {
            return false;
        }        
    }

    struct LiquidationDetails {
        address user;
        uint256 rewards;
    }

    function getAvailableLiquidations() public view returns(LiquidationDetails[] memory) {
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
                userRent = getUserTotalRent(users[ii]);
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
    }

    function liquidate(address _user) public returns(uint256) {
        uint256 liqThresh = IMain(_MAIN).getLiquidationThreshold();
        uint256 liqPen = IMain(_MAIN).getLiquidationPenalty();

        //User infos        
        uint256 userRent = getUserTotalRent(_user);
        uint256 userCollateral = _userCollateral[_user] - getRewardsFromUser(_user);
        uint256 balanceNeeded = userRent * liqThresh;
        require(balanceNeeded > userCollateral, "Liquidation not needed");
        updateRewards();

        //Calcul penalty
        uint256 userPenalty = (userCollateral * liqPen) / 1e18;
        address ERC721_Contract;
        uint256 nbContracts;
        uint256 ID;

        //For all markets ERC721_Contracts
        for(uint256 i ; i < IMain(_MAIN).getMarketCount() ; i++) {
            ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(i)).getERC721_Contract();
            nbContracts = IERC721x(ERC721_Contract).balanceOf(_user);

            //For all his open contracts, close it.
            for(uint256 ii ; ii < nbContracts ; ii++) {
                ID = IERC721x(ERC721_Contract).tokenOfOwnerByIndex(_user, ii);
                IMarketPool(IMain(_MAIN).getIdToMarket(i)).closeContract(ID);            
            }
        }

        //Send rewards to liquidator
        IERC20x(_COLLATERALTOKEN).transfer(msg.sender, userPenalty);
        _userCollateral[_user] -= userPenalty;

        return userPenalty;        
    }

    function liquidateContract(address _user, uint256 _index, uint256 _id) public returns(uint256) {
        uint256 liqThresh = IMain(_MAIN).getLiquidationThreshold();
        uint256 liqPen = IMain(_MAIN).getLiquidationPenalty();

        //User infos        
        uint256 userRent = getUserTotalRent(_user);
        uint256 userCollateral = _userCollateral[_user] - getRewardsFromUser(_user);
        uint256 balanceNeeded = userRent * liqThresh;
        require(balanceNeeded > userCollateral, "Liquidation not needed");
        updateRewards();

        //Calcul penalty
        uint256 userPenalty = (userCollateral * liqPen) / 1e18;
        address ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_Contract();

        //Close Contract
        uint256 ID = IERC721x(ERC721_Contract).tokenOfOwnerByIndex(_user, _id);
        IMarketPool(IMain(_MAIN).getIdToMarket(_index)).closeContract(ID);

        //Send rewards to liquidator
        IERC20x(_COLLATERALTOKEN).transfer(msg.sender, userPenalty);
        _userCollateral[_user] -= userPenalty;

        return userPenalty;        
    }

    function getMarketFees(uint256 _index) public view returns (uint256) {
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
    }

    mapping (uint256 => mapping(uint256 => uint256)) private lpsRewardsPerMarket;

    function getRewardsForLp(uint256 _index, uint256 _id) public view returns(uint256) {
        return lpsRewardsPerMarket[_index][_id];
    }

    function claim(uint256 _index, uint256 _id) public {
        IERC20x(_COLLATERALTOKEN).transfer(msg.sender, lpsRewardsPerMarket[_index][_id]);
        lpsRewardsPerMarket[_index][_id] = 0;
    }

    function getTotalRentPerStrikeForMarket(uint256 strike, uint256 _index) public view returns(uint256) {
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
    }

    function getRewardsPerStrikeForMarket(uint256 strike, uint256 _index) public view returns(uint256) {
        //For all lps in this market, if they have same strike, then cumulate rewards

        address ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_Contract();
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        uint256 currentTime = block.timestamp;
        uint256 rewards;

        //For all lps
        for(uint256 i ; i < IERC721x(ERC721_Contract).totalSupply() ; i++) {
            ID = IERC721x(ERC721_Contract).tokenByIndex(i);
            contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getContractInfos(ID);


            //if they have same strike
            if (contractInfos.strike == strike) {

                //If the option is younger than lastUpdate then "time = currentTime - start", else "time = currentTime - last update"
                if (contractInfos.start > lastUpdate) {
                    rewards += contractInfos.rent * (currentTime - contractInfos.start);
                } else {
                    rewards += contractInfos.rent * (currentTime - lastUpdate);
                }
            }             
        }

        return rewards;
    }

    function getLpsSharePerStrikeForMarket(uint256 strike, uint256 _index, uint256 _id) public view returns(uint256) {
        //For this market, For all lps with same strike, calculate share of the current Lps

        address ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_Contract();
        IMarketPool.ContractInfos memory lpInfos = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getContractInfos(_id);
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        uint256 totalAmountForStrike;
        uint256 share;

        //For all lps
        for(uint256 i ; i < IERC721x(ERC721_Contract).totalSupply() ; i++) {
            ID = IERC721x(ERC721_Contract).tokenByIndex(i);
            contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getContractInfos(ID);

            //if they have same strike
            if (contractInfos.strike == strike) {
                totalAmountForStrike += contractInfos.amount;
            }     
        }

        //Calculate share for the LP
        //share = option lpsamount / total amount on the strike still active
        share = (lpInfos.amount * 1e18) / totalAmountForStrike;

        return share;
    }

    function updateRewards() public {
        // For all markets, update all rewards per Lps based on their size per strike
        address ERC721_Contract;
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        address[] memory users;


        //For all markets
        for(uint256 i ; i < IMain(_MAIN).getMarketCount() ; i++) {
            ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(i)).getERC721_Contract();
            users = IERC721x(ERC721_Contract).getOwners();
            

            //For all lps
            for(uint256 ii ; ii < IERC721x(ERC721_Contract).totalSupply() ; ii++) {
                //add rewards
                ID = IERC721x(ERC721_Contract).tokenByIndex(i);
                contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(i)).getContractInfos(ID);
                uint256 strike = contractInfos.strike;
                uint256 rewardsPerStrike = getRewardsPerStrikeForMarket(strike, i);
                uint256 userShare = getLpsSharePerStrikeForMarket(strike, i, ii);
                uint256 reward = (userShare * rewardsPerStrike) / 1e18;
                lpsRewardsPerMarket[i][ii] += reward;
            }

            ////For all collateral users
            for(uint256 iii ; iii < users.length ; iii++) {
                //update their balance
                _userCollateral[users[iii]] = _userCollateral[users[iii]] - getRewardsFromUserForMarket(users[iii], i);
            }
        }

        lastUpdate = block.timestamp;
    }

}
