// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./interfaces/IMain.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IMarketPool.sol";
import "./interfaces/IERC20x.sol";
import "./interfaces/IERC721x.sol";

/// @title CollateralPool
/// @notice This contract manages collateral deposits, withdrawals, and reward claims for LPs.
contract CollateralPool {

    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event ContractLiquidated(address indexed liquidator, address indexed user, uint256 penalty);
    event RewardsClaimed(address indexed user, uint256 index, uint256 id, uint256 amount);

    address private _COLLATERALTOKEN; // Base Token
    uint256 private _COLLATERALTOKEN_DECIMALS;
    address private _MAIN;

    /// @param _collateralToken Address of the token used as collateral.
    /// @param _main Address of the main contract.    
    constructor(address _collateralToken, uint256 _collateralTokenDecimals, address _main) {
        _COLLATERALTOKEN = _collateralToken;
        _COLLATERALTOKEN_DECIMALS = _collateralTokenDecimals;
        _MAIN = _main;
    }

    ////////////////////////////////////////////////////////////////// BASE FUNCTIONS //////////////////////////////////////////////////////////////////

    /// @notice Returns the address of the main contract.
    /// @return Address of the main contract.
    function getMain() external view returns(address) {
        return _MAIN;
    }

    /// @notice Returns the address of the collateral Token.
    /// @return Address of the collateral Token.
    function getCollateralToken() external view returns(address) {
        return _COLLATERALTOKEN;
    }

    ////////////////////////////////////////////////////////////////// SET UP //////////////////////////////////////////////////////////////////

    struct UserInfos {
        uint256 collateral;
        uint256 rent;
        uint256 lastUpdate;
    }

    mapping(address => UserInfos) private _userInfos;

    ////////////////////////////////////////////////////////////////// INTERNAL //////////////////////////////////////////////////////////////////

    /// @notice Converts an amount from the collateral token's decimals to 18 decimals.
    /// @param _amount The amount in the collateral token's decimals to convert.
    /// @return The converted amount in 18 decimals.
    function collateralTokenTo18(uint256 _amount) private view returns(uint256) {
        return (_amount * 1e18)/10**_COLLATERALTOKEN_DECIMALS;
    }

    /// @notice Converts an amount from 18 decimals to the collateral token's decimals.
    /// @param _amount The amount in 18 decimals to convert.
    /// @return The converted amount in the collateral token's decimals.
    function toCollateralTokenDecimals(uint256 _amount) private view returns(uint256) {
        return (_amount * 10**_COLLATERALTOKEN_DECIMALS)/1e18;
    }

    ////////////////////////////////////////////////////////////////// GET FUNCTIONS //////////////////////////////////////////////////////////////////

    /// @notice Returns user information for a specific user.
    /// @param _user The address of the user.
    /// @return UserInfos structure containing collateral, rent, and last update timestamp.
    function getUserInfos(address _user) external view returns(UserInfos memory) {
        return _userInfos[_user];
    }

    /// @notice Calculates the accumulated fees for a user.
    /// @param _user The address of the user.
    /// @return The total fees accumulated for the user (18 decimals).
    function getUserFees(address _user) external view returns(uint256) {
        UserInfos memory thisUser =_userInfos[_user];
        return thisUser.rent * (block.timestamp - thisUser.lastUpdate);
    }

    /// @notice Returns the balance of collateral for a user after deducting rent fees.
    /// @param _user The address of the user.
    /// @return The net balance of the user (18 decimals).
    function balanceOf(address _user) public view returns(uint256) {
        if (_userInfos[_user].rent * (block.timestamp - _userInfos[_user].lastUpdate) > _userInfos[_user].collateral) {
            return 0;
        } else {
            return _userInfos[_user].collateral - _userInfos[_user].rent * (block.timestamp - _userInfos[_user].lastUpdate);
        }
    }

    /// @notice Calculates the rewards for a liquidity provider after deducting fees.
    /// @param _index The market index.
    /// @param _id The ID of the user's position in the market.
    /// @return The net rewards after fees (18 decimals).
    function getRewardsForLp(uint256 _index, uint256 _id) external view returns(uint256) {

        // Get infos
        uint256 rewards = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getRewards(_id);
        uint256 fees = IMain(_MAIN).getFees();
        uint256 feeAmount;

        if (fees > 0) {
            feeAmount = (rewards * IMain(_MAIN).getFees()) / 1e18;
        } else {
            feeAmount = 0;
        } 

        return rewards - feeAmount;
    }

    /// @notice Determines if a user can open a contract based on their collateral and rent.
    /// @param _user The address of the user.
    /// @param _rent The rent amount for the new contract.
    /// @return True if the user has sufficient collateral, otherwise false.
    function canOpenContract(address _user, uint256 _rent) external view returns(bool) {
        uint256 minCollateral = IMain(_MAIN).getMinCollateral();

        // User Infos
        uint256 userNewRent = _userInfos[_user].rent + _rent;
        uint256 userBalance = balanceOf(_user);
        uint256 balanceNeeded = userNewRent * minCollateral;

        // Returns
        if (userBalance > balanceNeeded) {
            return true;
        } else {
            return false;
        }        
    }

    /// @notice Checks if a user needs to be liquidated.
    /// @param _user The address of the user.
    /// @return True if liquidation is required, otherwise false.
    function needLiquidation(address _user) external view returns(bool) {
        uint256 liqThresh = IMain(_MAIN).getLiquidationThreshold();

        // User Infos
        uint256 userRent = _userInfos[_user].rent;
        uint256 userBalance = balanceOf(_user);
        uint256 balanceNeeded = userRent * liqThresh;

        // Returns
        if (balanceNeeded > userBalance) {
            return true;
        } else {
            return false;
        }        
    }    

    ////////////////////////////////////////////////////////////////// USERS FUNCTIONS //////////////////////////////////////////////////////////////////

    /// @notice Allows a user to deposit collateral into their account.
    /// @param _amount The amount of collateral to deposit.
    function depositCollateral(uint256 _amount) external {
        IERC20x(_COLLATERALTOKEN).transferFrom(msg.sender, address(this), _amount);
        _userInfos[msg.sender].collateral += collateralTokenTo18(_amount);

        // Emit event for collateral deposit
        emit CollateralDeposited(msg.sender, _amount);
    }

    /// @notice Allows a user to withdraw collateral if they have sufficient balance.
    /// @param _amount The amount of collateral to withdraw.
    function withdrawCollateral(uint256 _amount) external {
        uint256 amount = collateralTokenTo18(_amount);

        // Get infos
        uint256 minCollateral = IMain(_MAIN).getMinCollateral();
        uint256 userRent = _userInfos[msg.sender].rent;

        // Allowed to withdraw ?
        require(balanceOf(msg.sender) - amount >= userRent * minCollateral, "Not enough collateral");

        // Transfer and update user's infos
        IERC20x(_COLLATERALTOKEN).transfer(msg.sender, _amount);
        _userInfos[msg.sender].collateral -= amount;

        // Emit event for collateral withdrawal
        emit CollateralWithdrawn(msg.sender, _amount);
    }

    /// @notice Allows a user to claim rewards for a position they own.
    /// @param _index The market index.
    /// @param _id The ID of the user's position.
    function claimRewards(uint256 _index, uint256 _id) external {

        // Allowed to claim ?
        address idOwner = IERC721x(IMarketPool(IMain(_MAIN).getIdToMarket(_index)).getERC721_LP()).ownerOf(_id);
        require(tx.origin == idOwner, "You are not the owner of this LP");

        // Get infos
        uint256 rewards = IMarketPool(IMain(_MAIN).getIdToMarket(_index)).claimRewards(_id);
        uint256 fees = IMain(_MAIN).getFees();
        uint256 feeAmount;

        if (fees > 0) {
            feeAmount = (rewards * IMain(_MAIN).getFees()) / 1e18;
        } else {
            feeAmount = 0;
        }

        // Transfer
        IERC20x(_COLLATERALTOKEN).transfer(idOwner, toCollateralTokenDecimals(rewards - feeAmount));
        IERC20x(_COLLATERALTOKEN).transfer(IOwnable(_MAIN).owner(),toCollateralTokenDecimals(feeAmount));

        // Emit event for reward claimed
        emit RewardsClaimed(idOwner, _index, _id, toCollateralTokenDecimals(rewards));
    }

    /// @notice Liquidates a user's contract if they meet the liquidation criteria.
    /// @param _user The address of the user.
    /// @param _index The market index.
    /// @param _id The ID of the user's position.
    /// @return The penalty amount awarded to the liquidator (18 decimals).
    function liquidateContract(address _user, uint256 _index, uint256 _id) external returns(uint256) {

        // Get infos
        uint256 liqThresh = IMain(_MAIN).getLiquidationThreshold();
        uint256 liqPen = IMain(_MAIN).getLiquidationPenalty();

        // Need liquidation ?
        require(balanceOf(_user) < _userInfos[_user].rent * liqThresh, "No liquidation needed");

        // Calcul penalty
        uint256 penalty = (balanceOf(_user) * liqPen) / 1e18;

        // Close Contract
        IMarketPool(IMain(_MAIN).getIdToMarket(_index)).liquidateContract(_id);

        // Send rewards to liquidator
        IERC20x(_COLLATERALTOKEN).transfer(msg.sender, toCollateralTokenDecimals(penalty));
        _userInfos[_user].collateral -= penalty;

        // Emit event for contract liquidation
        emit ContractLiquidated(msg.sender, _user, toCollateralTokenDecimals(penalty));

        return penalty;        
    }

    ////////////////////////////////////////////////////////////////// VITALS //////////////////////////////////////////////////////////////////

    /**
     * @notice Updates the user's collateral and rent information in the contract.
     * @dev This function can only be called by Market Pools. It adjusts the user's
     *      collateral based on the time elapsed since the last update and either
     *      adds or subtracts rent depending on the `_isAdding` flag.
     * @param _user The address of the user whose information is being updated.
     * @param _isAdding Boolean flag indicating whether to add (`true`) or subtract (`false`) the specified `_rent`.
     * @param _rent The amount of rent to add or subtract from the user's total rent.
     * @param _lastUpdate The timestamp of the last update to synchronize the user's rent calculation.
     * @notice Reverts if called by an address other than a registered Market Pool.
     */
    function updateUserInfos(address _user, bool _isAdding, uint256 _rent, uint256 _lastUpdate) external {

        // Only for Market Pools
        uint256 marketId = IMain(_MAIN).getMarketId(msg.sender);
        require(IMain(_MAIN).getIdToMarket(marketId) == msg.sender, "Only for Market Pools");

        // Update user infos
        _userInfos[_user].collateral = balanceOf(_user);

        if (_isAdding) {
            _userInfos[_user].rent += _rent;
        } else {
            _userInfos[_user].rent -= _rent;
        }

        _userInfos[_user].lastUpdate = _lastUpdate;
    }

}
