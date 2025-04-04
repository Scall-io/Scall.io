// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "./interfaces/IMain.sol";
import "./interfaces/IMarketPool.sol";
import "./interfaces/IERC20x.sol";
import "./interfaces/IERC721x.sol";

import "hardhat/console.sol";

contract CollateralPool {

    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event ContractLiquidated(address indexed liquidator, address indexed user, uint256 penalty);
    event RewardsClaimed(address indexed user, uint256 index, uint256 id, uint256 amount);

    address private _COLLATERALTOKEN;
    address private _MAIN;

    uint256 public lastUpdate;
    
    constructor(address _collateralToken, address _main) {
        _COLLATERALTOKEN = _collateralToken;
        _MAIN = _main;
        lastUpdate = block.timestamp;
    }

    ////////////////////////////////////////////////////////////////// BASE FUNCTIONS //////////////////////////////////////////////////////////////////

    function getMain() public view returns(address) {
        return _MAIN;
    }

    ////////////////////////////////////////////////////////////////// SET UP //////////////////////////////////////////////////////////////////

    mapping(address => uint256) private _userCollateral;  
    mapping (uint256 => mapping(uint256 => uint256)) private _lpsRewardsPerMarket;    

    ////////////////////////////////////////////////////////////////// GET FUNCTIONS //////////////////////////////////////////////////////////////////

    function balanceOf(address _user) public view returns(uint256) {
        return _userCollateral[_user] - getFeesFromUser(_user);
    }

    function needLiquidation(address _user) public view returns(bool) {
        uint256 liqThresh = IMain(_MAIN).getLiquidationThreshold();

        //User Infos
        uint256 userRent = getUserRent( _user);
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
        uint256 userNewRent = getUserRent( _user) + _rent;
        uint256 userBalance = balanceOf( _user);
        uint256 balanceNeeded = userNewRent * liqThresh;

        //Returns
        if (balanceNeeded > userBalance) {
            return true;
        } else {
            return false;
        }        
    }

    function getFeesFromUser(address _user) public view returns(uint256 fees) {
        // For all markets ERC721_Contracts
        uint256 marketCount = IMain(_MAIN).getMarketCount();
        for(uint256 i ; i < marketCount ; i++) {
            fees += getFeesFromUserForMarket(_user, i);            
        }
    }

    function getFeesFromUserForMarket(address _user, uint256 _index) internal view returns (uint256 fees) {
        address ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_Contract();
        // For all actives user's options, add all rents
        for (uint256 i; i < IERC721x(ERC721_Contract).balanceOf(_user); i++) {
            fees += getFeesFromUserForMarketForContract(_user, _index, i);
        }
    }

    function getFeesFromUserForMarketForContract(address _user, uint256 _index, uint256 _id) public view returns(uint256 fees) {
        //Initialize Variables
        address ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_Contract();
        uint256 ID = IERC721x(ERC721_Contract).tokenOfOwnerByIndex(_user, _id);
        IMarketPool.ContractInfos memory contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getContractInfos(ID);
        uint256 currentTime = block.timestamp;

        //If the option is younger than lastUpdate then "time = currentTime - start", else "time = currentTime - last update"
        if (contractInfos.start > lastUpdate) {
            fees += contractInfos.rent * (currentTime - contractInfos.start);
        } else {
            fees += contractInfos.rent * (currentTime - lastUpdate);
        }
    }

    function getUserRent(address _user) public view returns(uint256 rent) {
        // For all markets ERC721_Contracts
        uint256 marketCount = IMain(_MAIN).getMarketCount();
        for(uint256 i ; i < marketCount ; i++) {
            rent += getUserRentForMarket(_user, i);           
        }
    }

    function getUserRentForMarket(address _user, uint256 _index) public view returns(uint256 rent) {
        //Initialize Variables
        address ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_Contract();
        uint256 balanceOfUser = IERC721x(ERC721_Contract).balanceOf(_user);

        // For all actives user's options, add all rents
        for(uint256 i ; i < balanceOfUser ; i++) {
            rent += getUserRentForMarketForContract(_user, _index, i);
        }
    }

    function getUserRentForMarketForContract(address _user, uint256 _index, uint256 _id) public view returns(uint256 rent) {
        address ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_Contract();
        uint256 ID = IERC721x(ERC721_Contract).tokenOfOwnerByIndex(_user, _id);
        IMarketPool.ContractInfos memory contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getContractInfos(ID);
        rent = contractInfos.rent;
    }

    function getRewardsForLp(uint256 _index, uint256 _id) public view returns(uint256) {
        return _lpsRewardsPerMarket[_index][_id];
    }

    function getRewardsPerStrikeForMarket(uint256 strike, uint256 _index, bool _isCall) public view returns(uint256 rewards) {
        //For all lps in this market, if they have same strike, then cumulate rewards

        address ERC721_LP = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_LP();
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        uint256 currentTime = block.timestamp;
        uint256 totalSupply = IERC721x(ERC721_LP).totalSupply();

        //For all lps
        for(uint256 i ; i < totalSupply ; i++) {
            ID = IERC721x(ERC721_LP).tokenByIndex(i);
            contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getContractInfos(ID);

            //if ther are the same type (call or put)
            if (contractInfos.isCall == _isCall) {

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
        }
    }

    function getLpsSharePerStrikeForMarket(uint256 strike, uint256 _index, uint256 _id, bool _isCall) public view returns(uint256 share) {
        //For this market, For all lps with same strike, calculate share of the current Lps

        address ERC721_LP = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_LP();
        IMarketPool.ContractInfos memory lpInfos = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getContractInfos(_id);
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        uint256 totalAmountForStrike;
        uint256 totalSupply = IERC721x(ERC721_LP).totalSupply();

        //For all lps
        for(uint256 i ; i < totalSupply ; i++) {
            ID = IERC721x(ERC721_LP).tokenByIndex(i);
            contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getContractInfos(ID);

            //if ther are the same type (call or put)
            if (contractInfos.isCall == _isCall) {

                //if they have same strike
                if (contractInfos.strike == strike) {
                    totalAmountForStrike += contractInfos.amount;
                }
            }    
        }

        //Calculate share for the LP
        //share = option lpsamount / total amount on the strike still active
        share = (lpInfos.amount * 1e18) / totalAmountForStrike;
    }

    ////////////////////////////////////////////////////////////////// USERS FUNCTIONS //////////////////////////////////////////////////////////////////

    function depositCollateral(uint256 _amount) public {
        IERC20x(_COLLATERALTOKEN).transferFrom(msg.sender, address(this), _amount);
        _userCollateral[msg.sender] += _amount;

        // Emit event for collateral deposit
        emit CollateralDeposited(msg.sender, _amount);
    }

    function withdrawCollateral(uint256 _amount) public {
        uint256 minCollateral = IMain(_MAIN).getMinCollateral();
        uint256 userRent = getUserRent(msg.sender);

        //Il faut que collateral restant soit > à user rend x minCollateral
        require(balanceOf(msg.sender) - _amount >= userRent * minCollateral, "Not enough collateral");

        IERC20x(_COLLATERALTOKEN).transfer(msg.sender, _amount);
        _userCollateral[msg.sender] -= _amount;

        // Emit event for collateral withdrawal
        emit CollateralWithdrawn(msg.sender, _amount);
    }

    function claim(uint256 _index, uint256 _id) public {
        uint256 rewards = _lpsRewardsPerMarket[_index][_id];
        IERC20x(_COLLATERALTOKEN).transfer(msg.sender, rewards);
        _lpsRewardsPerMarket[_index][_id] = 0;

        // Emit event for rewards claim
        emit RewardsClaimed(msg.sender, _index, _id, rewards);
    }

    function liquidate(address _user) public returns(uint256) {
        uint256 liqThresh = IMain(_MAIN).getLiquidationThreshold();
        uint256 liqPen = IMain(_MAIN).getLiquidationPenalty();

        require(balanceOf(_user) < getUserRent(_user) * liqThresh, "No liquidation needed");
        updateRewards();

        //Calcul penalty
        uint256 penalty = (_userCollateral[_user] * liqPen) / 1e18;
        address ERC721_Contract;
        uint256 nbContracts;
        uint256 ID;
        uint256 marketCount = IMain(_MAIN).getMarketCount();

        //For all markets ERC721_Contracts
        for(uint256 i ; i < marketCount ; i++) {
            ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(i)).getERC721_Contract();
            nbContracts = IERC721x(ERC721_Contract).balanceOf(_user);

            //For all his open contracts, close it.
            for(uint256 ii ; ii < nbContracts ; ii++) {
                ID = IERC721x(ERC721_Contract).tokenOfOwnerByIndex(_user, ii);
                IMarketPool(IMain(_MAIN).getIdToMarket(i)).closeContract(ID);            
            }
        }

        //Send rewards to liquidator
        IERC20x(_COLLATERALTOKEN).transfer(msg.sender, penalty);
        _userCollateral[_user] -= penalty;

        // Emit event for contract liquidation
        emit ContractLiquidated(msg.sender, _user, penalty);

        return penalty;        
    }

    ////////////////////////////////////////////////////////////////// VITALS //////////////////////////////////////////////////////////////////

    function updateRewards() public {
        // For all markets, update all rewards per Lps based on their size per strike
        address ERC721_LP;
        address ERC721_Contract;
        uint256 ID;
        IMarketPool.ContractInfos memory contractInfos;
        address[] memory users;
        uint256 rewardsPerStrike;
        uint256 userShare;
        uint256 reward;
        uint256 marketCount = IMain(_MAIN).getMarketCount();
        uint256 totalSupply;

        //For all markets
        for(uint256 i ; i < marketCount ; i++) {
            ERC721_LP = IMarketPool(IMain(_MAIN).getIdToMarket(i)).getERC721_LP();
            totalSupply = IERC721x(ERC721_LP).totalSupply();

            //For all lps
            for(uint256 ii ; ii < totalSupply ; ii++) {
                //add rewards
                ID = IERC721x(ERC721_LP).tokenByIndex(i);
                contractInfos = IMarketPool(IMain(_MAIN).getIdToMarket(i)).getContractInfos(ID);
                rewardsPerStrike = getRewardsPerStrikeForMarket(contractInfos.strike, i, contractInfos.isCall);
                userShare = getLpsSharePerStrikeForMarket(contractInfos.strike, i, ii, contractInfos.isCall);
                reward = (userShare * rewardsPerStrike) / 1e18;
                _lpsRewardsPerMarket[i][ii] += reward;
            }

            ERC721_Contract = IMarketPool(IMain(_MAIN).getIdToMarket(i)).getERC721_Contract();
            users = IERC721x(ERC721_Contract).getOwners();

            ////For all collateral users
            for(uint256 iii ; iii < users.length ; iii++) {
                //update their balance
                _userCollateral[users[iii]] -= getFeesFromUserForMarket(users[iii], i);
            }
        }

        lastUpdate = block.timestamp;
    }

}
