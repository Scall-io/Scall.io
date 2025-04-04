// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC721_Contract.sol";
import "./ERC721_LP.sol";
import "./interfaces/IChainlink.sol";
import "./interfaces/IERC20x.sol";
import "./interfaces/IERC721x.sol";
import "./interfaces/IMain.sol";
import "./interfaces/ICollateralPool.sol";

/// @title MarketPool - Manages perpetual options with liquidity provision and collateral
/// @notice This contract allows users to deposit liquidity, withdraw liquidity, open, and close option contracts.
/// @dev Interacts with external ERC20 and ERC721 contracts to manage assets and NFT-based positions.
contract MarketPool {

    event Deposit(address indexed user, bool isCall, uint256 amount, uint256 strike, uint256 lpId);
    event Withdraw(address indexed user, uint256 lpId, uint256 amountA, uint256 amountB);
    event ContractOpened(address indexed user, bool isCall, uint256 amount, uint256 strike, uint256 contractId);
    event ContractClosed(address indexed user, uint256 contractId, uint256 amount);

    //Base
    uint256 private _lpCount;
    uint256 private _contractCount;

    //Contract Address
    address private _MAIN;
    address private _ERC721_CONTRACT;
    address private _ERC721_LP;

    //Not Variable
    address private _TOKENA; // Asset
    uint256 private _TOKENA_DECIMALS;
    address private _TOKENB; // Collateral Token
    uint256 private _TOKENB_DECIMALS;

    //Variable
    address private _PRICEFEED;
    uint256 private _PRICEFEED_DECIMAL;
    uint256 private _INTERVALLENGTH;
    uint256 private _RANGE;
    uint256 private _YIELD;

    /// @notice Initializes the MarketPool contract with the provided parameters and deploys two ERC721 contracts for options and liquidity positions.
    /// @param _main Address of the main contract governing the market pool.
    /// @param _tokenA Address of the asset token for call options.
    /// @param _tokenB Address of the collateral token for put options.
    /// @param _pricefeed Address of the Chainlink price feed contract for the underlying asset.
    /// @param _pricefeedDecimal The number of decimals used in the Chainlink price feed data.
    /// @param _range The range for strike prices based on the current price.
    /// @param _yield The yield percentage used to calculate premium costs.    
    constructor(address _main, address _tokenA, uint8 _tokenADecimals, address _tokenB, uint8 _tokenBDecimals, address _pricefeed, uint256 _pricefeedDecimal, uint256 _intervalLength, uint256 _range, uint256 _yield) {
        _MAIN = _main;
        _TOKENA = _tokenA;
        _TOKENA_DECIMALS = _tokenADecimals;
        _TOKENB = _tokenB;
        _TOKENB_DECIMALS = _tokenBDecimals;
        
        ERC721_Contract erc721_contract = new ERC721_Contract(address(this), "XPO", "XPO");
        _ERC721_CONTRACT = address(erc721_contract);

        ERC721_LP erc721_lp = new ERC721_LP(address(this), "LP", "LP");
        _ERC721_LP = address(erc721_lp);

        _PRICEFEED = _pricefeed;
        _PRICEFEED_DECIMAL = _pricefeedDecimal;
        _INTERVALLENGTH = _intervalLength;
        _RANGE = _range;
        _YIELD = _yield;
    }

    ////////////////////////////////////////////////////////////////// SET UP //////////////////////////////////////////////////////////////////

    struct StrikeInfos {
        uint256 callLP;
        uint256 callLU;
        uint256 callLR;
        uint256 putLP;
        uint256 putLU;
        uint256 putLR;
        uint256 updateCount;
        uint256 updated;
    }  

    struct LpInfos {
        bool isCall;
        uint256 strike;
        uint256 amount;
        uint256 start;
        uint256 lastClaim;
    }  

    struct ContractInfos {
        bool isCall;
        uint256 strike;
        uint256 amount;
        uint256 rent;
        uint256 start;
    }

    mapping(uint256 => LpInfos) private _lpIdToInfos;
    mapping(uint256 => ContractInfos) private _contractIdToInfos;
    mapping(uint256 => StrikeInfos) private _strikeToInfos;
    mapping(uint256 => mapping(uint256 => StrikeInfos)) private _strikeHistory;


    ////////////////////////////////////////////////////////////////// BASE FUNCTIONS //////////////////////////////////////////////////////////////////

    /// @notice Returns the address of the main contract
    /// @return The address of the main contract
    function getMain() external view returns(address) {
        return _MAIN;
    }

    /// @notice Returns the address of the ERC721 contract for user positions
    /// @return The address of the ERC721 contract
    function getERC721_Contract() external view returns(address) {
        return _ERC721_CONTRACT;
    }

    /// @notice Returns the address of the ERC721 contract for liquidity provider positions
    /// @return The address of the ERC721 LP contract
    function getERC721_LP() external view returns(address) {
        return _ERC721_LP;
    }

    /// @notice Returns the address of Token A (the asset)
    /// @return The address of Token A
    function getTokenA() external view returns(address) {
        return _TOKENA;
    }

    /// @notice Returns the address of Token B (collateral token)
    /// @return The address of Token B
    function getTokenB() external view returns(address) {
        return _TOKENB;
    }

    // @notice Returns the address of the price feed contract
    /// @return The address of the price feed
    function getPriceFeed() external view returns(address) {
        return _PRICEFEED;
    }

    /// @notice Returns the range parameter used in pricing intervals
    /// @return The range parameter value
    function getIntervalLength() external view returns(uint256) {
        return _INTERVALLENGTH;
    }

    /// @notice Returns the range parameter used in pricing intervals
    /// @return The range parameter value
    function getRange() external view returns(uint256) {
        return _RANGE;
    }

    /// @notice Returns the yield rate for options
    /// @return The yield rate
    function getYield() external view returns(uint256) {
        return _YIELD;
    }

    /// @notice Retrieves the details of a specific contract by ID
    /// @param _id The ID of the contract
    /// @return ContractInfos struct containing contract details
    function getContractInfos(uint256 _id) external view returns(ContractInfos memory) {
        return _contractIdToInfos[_id];
    }

    /// @notice Retrieves the details of a specific LP position by ID
    /// @param _id The ID of the LP position
    /// @return LpInfos struct containing LP position details
    function getLpInfos(uint256 _id) external view returns(LpInfos memory) {
        return _lpIdToInfos[_id];        
    }

    /// @notice Retrieves information about a specific strike
    /// @param _strike The strike price for which information is requested
    /// @return StrikeInfos struct containing strike information
    function getStrikeInfos(uint256 _strike) external view returns(StrikeInfos memory) {
        return _strikeToInfos[_strike];
    }

    /// @notice Retrieves historical information for a specific strike and period index
    /// @param _strike The strike price for which history is requested
    /// @param _index The period index
    /// @return StrikeInfos struct containing historical data
    function getStrikeHistory(uint256 _strike, uint256 _index) external view returns(StrikeInfos memory) {
        return _strikeHistory[_strike][_index];
    }

    /// @notice Updates the price feed and decimal values
    /// @dev Can only be called by the main contract
    /// @param _priceFeed The new price feed address
    /// @param _decimal The decimal precision of the price feed
    function setPriceFeed(address _priceFeed, uint256 _decimal) external {
        require(msg.sender == _MAIN, "You are not allowed");
        _PRICEFEED = _priceFeed;
        _PRICEFEED_DECIMAL = _decimal;
    }

    /// @notice Updates the interval length
    /// @dev Can only be called by the main contract
    /// @param _length The new length value
    function setIntervalLength(uint256 _length) external {
        require(msg.sender == _MAIN, "You are not allowed");
        require(_length > 0 && _length % 2 == 0, "Invalid length: Must be a positive even number");
        _INTERVALLENGTH = _length;
    }

    /// @notice Updates the range value
    /// @dev Can only be called by the main contract
    /// @param _range The new range value
    function setRange(uint256 _range) external {
        require(msg.sender == _MAIN, "You are not allowed");
        _RANGE = _range;
    }

    /// @notice Updates the yield rate
    /// @dev Can only be called by the main contract
    /// @param _yield The new yield rate
    function setYield(uint256 _yield) external {
        require(msg.sender == _MAIN, "You are not allowed");
        _YIELD = _yield;
    }

    ////////////////////////////////////////////////////////////////// INTERNAL //////////////////////////////////////////////////////////////////

    /// @notice Converts an amount from Token A's decimals to 18 decimals.
    /// @param _amount The amount in Token A's decimals to convert.
    /// @return The converted amount in 18 decimals.
    function tokenATo18(uint256 _amount) private view returns(uint256) {
        return (_amount * 1e18)/10**_TOKENA_DECIMALS;
    }

    /// @notice Converts an amount from Token B's decimals to 18 decimals.
    /// @param _amount The amount in Token B's decimals to convert.
    /// @return The converted amount in 18 decimals
    function tokenBTo18(uint256 _amount) private view returns(uint256) {
        return (_amount * 1e18)/10**_TOKENB_DECIMALS;
    }

    /// @notice Converts an amount from 18 decimals to Token A's decimals.
    /// @param _amount The amount in 18 decimals to convert.
    /// @return The converted amount in Token A's decimals.
    function toTokenADecimals(uint256 _amount) private view returns(uint256) {
        return (_amount * 10**_TOKENA_DECIMALS)/1e18;
    }

    /// @notice Converts an amount from 18 decimals to Token B's decimals.
    /// @param _amount The amount in 18 decimals to convert.
    /// @return The converted amount in Token B's decimals.
    function toTokenBDecimals(uint256 _amount) private view returns(uint256) {
        return (_amount * 10**_TOKENB_DECIMALS)/1e18;
    }

    ////////////////////////////////////////////////////////////////// GET FUNCTIONS //////////////////////////////////////////////////////////////////

    /// @notice Fetches the current price of the underlying asset from the Chainlink price feed.
    /// @return The current price of the asset, adjusted to a standard 18 decimal format.
    function getPrice() public view returns(uint256) {
        (, int result,,,) = IChainlink(_PRICEFEED).latestRoundData();
        return uint256(result) * (1e18/10**_PRICEFEED_DECIMAL);
    }

    /// @notice Returns the interval range around the current price based on a defined range value.
    /// @dev Calculates a lower and upper bound around the current price, expanded by `_RANGE` on both sides.
    /// @return An array containing the lower and upper bounds of the interval.
    function getIntervals() public view returns(uint256[] memory) {
        uint256 currentPrice = getPrice();

        uint256 modulo = currentPrice % _RANGE;

        uint256 lowerBound = currentPrice - modulo;
        uint256 upperBound = lowerBound + _RANGE;

        uint256[] memory intervals = new uint256[](_INTERVALLENGTH);

        uint256 halfLength = _INTERVALLENGTH / 2;

        // Fill the first half with lower bounds
        for (uint256 i = 0; i < halfLength; i++) {
            intervals[i] = lowerBound - _RANGE * (i + 1);
        }

        // Fill the second half with upper bounds
        for (uint256 i = halfLength; i < _INTERVALLENGTH; i++) {
            intervals[i] = upperBound + _RANGE * (i - halfLength + 1);
        }

        return intervals;
    }

    /// @notice Calculates and returns the accumulated rewards for a specified liquidity position.
    /// @dev Iterates through historical strike data to calculate the reward based on the user's share, type of position (call or put), and time spent in each period since the last claim.
    /// @param _id The unique ID of the liquidity position for which rewards are calculated.
    /// @return rewards The total calculated rewards for the specified liquidity position (18 decimals).
    function getRewards(uint256 _id) public view returns(uint256) {

        // Get Infos
        LpInfos memory thisLP = _lpIdToInfos[_id];
        StrikeInfos memory thisStrike = _strikeToInfos[thisLP.strike];
        uint256 currentTime = block.timestamp;

        // Initialize Variables
        StrikeInfos memory thisStrikeCount;
        StrikeInfos memory olderStrikeCount;
        uint256 rewardsPerStrike;
        uint256 userShare;
        uint256 timeSpent;
        uint256 rewards;

        // For all history index
        for(uint256 i = thisStrike.updateCount - 1 ; i >= 0  ; i--) {
            thisStrikeCount = _strikeHistory[thisLP.strike][i];

            // if it's not the last period
            if(thisLP.lastClaim < thisStrikeCount.updated) {

                // if it's the first index
                if(i == thisStrike.updateCount - 1) {
                    timeSpent = currentTime - thisStrikeCount.updated;
                } else {
                    olderStrikeCount = _strikeHistory[thisLP.strike][i+1];
                    timeSpent = olderStrikeCount.updated - thisStrikeCount.updated;
                }

            } else /* if it's the last period */ {

                // if it's the first index
                if(i == thisStrike.updateCount - 1) {
                    timeSpent = currentTime - thisLP.lastClaim;
                } else {
                    olderStrikeCount = _strikeHistory[thisLP.strike][i+1];
                    timeSpent = olderStrikeCount.updated - thisLP.lastClaim;
                }

            }            

            // Call or Put ?
            if (thisLP.isCall) {
                rewardsPerStrike = ((((thisStrikeCount.callLU * thisLP.strike)/1e18) * _YIELD)/1e18)/31536000 * timeSpent;
                userShare = ((thisLP.amount * 1e18) / thisStrikeCount.callLP);
            } else {
                rewardsPerStrike = ((thisStrikeCount.putLU * _YIELD)/1e18)/31536000 * timeSpent;
                userShare = ((thisLP.amount * 1e18) / thisStrikeCount.putLP);
            }

            // Calcul Rewards
            rewards += (userShare * rewardsPerStrike) / 1e18;

            // Break if it's the last period
            if(thisLP.lastClaim >= thisStrikeCount.updated) {
                break;
            }
        }

        return rewards;
    }

    ////////////////////////////////////////////////////////////////// USERS FUNCTIONS //////////////////////////////////////////////////////////////////

    /// @notice Allows a user to deposit assets and open an LP position
    /// @dev Mints an NFT for the LP position and updates liquidity information
    /// @param _isCall Specifies if the option is a call or a put
    /// @param _amount The amount of assets to deposit
    /// @return _lpCount - 1 The unique ID assigned to the newly created LP position.
    function deposit(bool _isCall, uint256 _amount) external returns(uint256) {
        require(_amount > 1e2, "_amount too low");

        // Get Interval
        uint256[] memory interval = getIntervals();
        uint256 strike;
        uint256 amount;

        // Transfer token, get Strike and update strike Infos
        if (_isCall) {
            IERC20x(_TOKENA).transferFrom(msg.sender, address(this), _amount);
            strike = interval[_INTERVALLENGTH / 2];
            amount = tokenATo18(_amount);
            _strikeToInfos[strike].callLP += amount;
        } else {
            IERC20x(_TOKENB).transferFrom(msg.sender, address(this), _amount);
            strike = interval[0];
            amount = tokenBTo18(_amount);
            _strikeToInfos[strike].putLP += amount;
        }

        // Set Lp position
        LpInfos memory newLP = LpInfos(_isCall, strike, amount, block.timestamp, block.timestamp);
        _lpIdToInfos[_lpCount] = newLP;
        IERC721x(_ERC721_LP).mint(msg.sender, _lpCount);

        // Feed Strike History
        _strikeToInfos[strike].updated = block.timestamp;
        _strikeHistory[strike][_strikeToInfos[strike].updateCount] = _strikeToInfos[strike];
        _strikeToInfos[strike].updateCount += 1;

        // Emit the deposit event
        emit Deposit(msg.sender, _isCall, _amount, strike, _lpCount);

        _lpCount++;  

        return  (_lpCount - 1);     
    }

    /// @notice Allows a user to withdraw assets from an LP position
    /// @dev Claims rewards for the LP position before withdrawal and burns the NFT if fully withdrawn
    /// @param _id The ID of the LP position to withdraw from
    /// @return tokenAtoTransfer The amount of token A withdrawn by the LP (token decimals).
    /// @return tokenBtoTransfer The amount of token B withdrawn by the LP (token decimals).
    /// @return claimedRewards The additional reward amount received by the LP (token decimals).
    function withdraw(uint256 _id) external returns(uint256, uint256, uint256) {
        require(msg.sender == IERC721x(_ERC721_LP).ownerOf(_id), "You are not the owner");

        // Claim Rewards
        uint256 claimedRewards = ICollateralPool(IMain(_MAIN).getCollateralPool()).claimRewards(IMain(_MAIN).getMarketId(address(this)), _id);
        
        // Get Infos
        LpInfos memory thisLP = _lpIdToInfos[_id];
        StrikeInfos memory strikeInfos = _strikeToInfos[thisLP.strike];
        uint256 liquidityReturned;
        uint256 availableFunds;
        uint256 tokenAtoTransfer;
        uint256 tokenBtoTransfer;

        // Call or Put ?
        if (thisLP.isCall) {

            availableFunds = strikeInfos.callLP - strikeInfos.callLU;

            if (strikeInfos.callLR > 0) {

                liquidityReturned = (strikeInfos.callLR * 1e18)/thisLP.strike;

                // If available funds can't cover LP amount
                if (availableFunds < thisLP.amount) {

                    // Transfers
                    tokenBtoTransfer = strikeInfos.callLR;
                    tokenAtoTransfer = availableFunds - liquidityReturned;

                    // Changes
                    _strikeToInfos[thisLP.strike].callLR = 0;
                    _lpIdToInfos[_id].amount -= availableFunds;
                    _strikeToInfos[thisLP.strike].callLP -= availableFunds;

                } else {

                    if (liquidityReturned >= thisLP.amount ) {

                        // Transfers
                        tokenBtoTransfer = (thisLP.amount * thisLP.strike)/1e18;
                        tokenAtoTransfer = 0;

                        // Changes
                        _strikeToInfos[thisLP.strike].callLR -= (thisLP.amount * thisLP.strike)/1e18;
                        _strikeToInfos[thisLP.strike].callLP -= thisLP.amount;
                        IERC721x(_ERC721_LP).burn(_id);

                    } else {

                        // Transfers
                        tokenBtoTransfer = strikeInfos.callLR;
                        tokenAtoTransfer = thisLP.amount - liquidityReturned;

                        // Changes
                        _strikeToInfos[thisLP.strike].callLR = 0;
                        _strikeToInfos[thisLP.strike].callLP -= thisLP.amount;
                        IERC721x(_ERC721_LP).burn(_id);
                    }

                }

            } else {

                // If available funds can't cover LP amount
                if (availableFunds < thisLP.amount) {

                    // Transfers
                    tokenBtoTransfer = 0;
                    tokenAtoTransfer = availableFunds;

                    // Changes
                    _lpIdToInfos[_id].amount -= availableFunds;
                    _strikeToInfos[thisLP.strike].callLP -= availableFunds;

                } else {

                    // Transfers
                    tokenBtoTransfer = 0;
                    tokenAtoTransfer = thisLP.amount;

                    // Changes
                    _strikeToInfos[thisLP.strike].callLP -= thisLP.amount;
                    IERC721x(_ERC721_LP).burn(_id);
                }

            }
            

        } else {

            availableFunds = strikeInfos.putLP - strikeInfos.putLU;

            if (strikeInfos.putLR > 0) {

                liquidityReturned = (strikeInfos.putLR * thisLP.strike)/1e18;

                // If available funds can't cover LP amount
                if (availableFunds < thisLP.amount) {

                    // Transfers
                    tokenAtoTransfer = strikeInfos.putLR;
                    tokenBtoTransfer = availableFunds - liquidityReturned;

                    // Changes
                    _strikeToInfos[thisLP.strike].putLR = 0;
                    _lpIdToInfos[_id].amount -= availableFunds;
                    _strikeToInfos[thisLP.strike].putLP -= availableFunds;

                } else {

                    if (liquidityReturned >= thisLP.amount) {

                        // Transfers
                        tokenAtoTransfer = (thisLP.amount * 1e18)/thisLP.strike;
                        tokenBtoTransfer = 0;

                        // Changes
                        _strikeToInfos[thisLP.strike].putLR -= (thisLP.amount * 1e18)/thisLP.strike;
                        _strikeToInfos[thisLP.strike].putLP -= thisLP.amount;
                        IERC721x(_ERC721_LP).burn(_id);

                    } else {

                        // Transfers
                        tokenAtoTransfer = strikeInfos.putLR;
                        tokenBtoTransfer = thisLP.amount - liquidityReturned;

                        // Changes
                        _strikeToInfos[thisLP.strike].putLR = 0;
                        _strikeToInfos[thisLP.strike].putLP -= thisLP.amount;
                        IERC721x(_ERC721_LP).burn(_id);

                    }

                }


            } else {

                // If available funds can't cover LP amount
                if (availableFunds < thisLP.amount) {

                    // Transfers
                    tokenAtoTransfer = 0;
                    tokenBtoTransfer = availableFunds;

                    // Changes
                    _lpIdToInfos[_id].amount -= availableFunds;
                    _strikeToInfos[thisLP.strike].putLP -= availableFunds;

                } else {

                    // Transfers
                    tokenAtoTransfer = 0;
                    tokenBtoTransfer = thisLP.amount;

                    // Changes
                    _strikeToInfos[thisLP.strike].putLP -= thisLP.amount;
                    IERC721x(_ERC721_LP).burn(_id);

                }
            }
        }

        // Feed Strike History
        _strikeToInfos[thisLP.strike].updated = block.timestamp;
        _strikeHistory[thisLP.strike][_strikeToInfos[thisLP.strike].updateCount] = _strikeToInfos[thisLP.strike];
        _strikeToInfos[thisLP.strike].updateCount += 1;

        // Transfers
        if (tokenAtoTransfer > 0) {
            IERC20x(_TOKENA).transfer(msg.sender, toTokenADecimals(tokenAtoTransfer));
        }

        if (tokenBtoTransfer > 0) {
            IERC20x(_TOKENB).transfer(msg.sender, toTokenBDecimals(tokenBtoTransfer));
        }

        // Emit the withdrawal event
        emit Withdraw(msg.sender, _id, toTokenADecimals(tokenAtoTransfer), toTokenBDecimals(tokenBtoTransfer));

        return (toTokenADecimals(tokenAtoTransfer), toTokenBDecimals(tokenBtoTransfer), claimedRewards);                
    } 

    /// @notice Opens a new option contract using liquidity provided in the pool
    /// @dev Mints an NFT for the option contract and updates liquidity information
    /// @param _isCall Specifies if the option is a call or a put
    /// @param _amount The amount of assets for the option contract
    function openContract(bool _isCall, uint256 _strikeIndex, uint256 _amount) external {
        require(_amount > 1e2, "_amount too low");
        require(_strikeIndex < _INTERVALLENGTH / 2, "Wrong Strike Index");

        // Intervals Check
        uint256[] memory intervals = getIntervals();        

        // Get infos
        uint256 strike;
        uint256 amount;
        uint256 availableLiquidity;
        uint256 rent;
        if (_isCall) {
            strike = intervals[_strikeIndex + (_INTERVALLENGTH / 2)];
            amount = tokenATo18(_amount);
            availableLiquidity = _strikeToInfos[strike].callLP - _strikeToInfos[strike].callLU - (_strikeToInfos[strike].callLR*1e18)/strike;
            rent = ((((amount*strike)/1e18)*_YIELD)/1e18)/31536000;
        } else {
            strike = intervals[_strikeIndex];
            amount = tokenBTo18(_amount);
            availableLiquidity = _strikeToInfos[strike].putLP - _strikeToInfos[strike].putLU - (_strikeToInfos[strike].putLR*strike)/1e18;
            rent = ((amount*_YIELD)/1e18)/31536000;
        }

        // Security
        require(ICollateralPool(IMain(_MAIN).getCollateralPool()).canOpenContract(msg.sender, rent), "No enough collateral");
        require(amount <= availableLiquidity, "No enough liquidity");

        // Update Liquidity Usage after checks
        if (_isCall == true) {
            _strikeToInfos[strike].callLU += amount;
        } else {
            _strikeToInfos[strike].putLU += amount;
        }

        // Set Contract
        ContractInfos memory newContract = ContractInfos(_isCall, strike, amount, rent, block.timestamp);
        _contractIdToInfos[_contractCount] = newContract;
        IERC721x(_ERC721_CONTRACT).mint(msg.sender, _contractCount);

        // Update CollateralPool
        ICollateralPool(IMain(_MAIN).getCollateralPool()).updateUserInfos(msg.sender, true, rent, block.timestamp);

        // Feed Strike History
        _strikeToInfos[strike].updated = block.timestamp;
        _strikeHistory[strike][_strikeToInfos[strike].updateCount] = _strikeToInfos[strike];
        _strikeToInfos[strike].updateCount += 1;

        // Emit the contract opened event
        emit ContractOpened(msg.sender, _isCall, _amount, strike, _contractCount);

        _contractCount++;
    }

    
    /// @notice Closes an open contract position, settles based on the current price, and burns the contract NFT.
    /// @dev Checks if the caller is the contract owner. Determines if the position is a call or put and settles the contract based on the current price relative to the strike price.
    /// @param _id The unique ID of the contract to close.
    function closeContract(uint256 _id) external {
        require(msg.sender == IERC721x(_ERC721_CONTRACT).ownerOf(_id), "You are not the owner");

        // Get Infos
        ContractInfos memory userContract = _contractIdToInfos[_id];
        address contractOwner = IERC721x(_ERC721_CONTRACT).ownerOf(_id);
        uint256 currentPrice = getPrice();

        // Call or Put ?
        if (userContract.isCall) {

            // if contract ITM, then pay strike x amount and receive amount (token call), else nothing
            if (currentPrice > userContract.strike) {
                IERC20x(_TOKENB).transferFrom(msg.sender, address(this), toTokenBDecimals((userContract.strike * userContract.amount)/1e18));
                IERC20x(_TOKENA).transfer(msg.sender, toTokenADecimals(userContract.amount));
                _strikeToInfos[userContract.strike].callLR += (userContract.strike * userContract.amount)/1e18;
            }

            _strikeToInfos[userContract.strike].callLU -= userContract.amount;

        } else {

            // if contract ITM, then pay amount (token Put) and receive strike x amount, else nothing
            if (currentPrice < userContract.strike) {
                IERC20x(_TOKENA).transferFrom(msg.sender, address(this), toTokenADecimals((userContract.amount * 1e18)/userContract.strike));
                IERC20x(_TOKENB).transfer(msg.sender, toTokenBDecimals(userContract.amount));
                _strikeToInfos[userContract.strike].putLR += (userContract.amount * 1e18)/userContract.strike;
                
            }

            _strikeToInfos[userContract.strike].putLU -= userContract.amount;

        }

        // Update CollateralPool
        ICollateralPool(IMain(_MAIN).getCollateralPool()).updateUserInfos(contractOwner, false, userContract.rent, block.timestamp);

        // Feed Strike History
        _strikeToInfos[userContract.strike].updated = block.timestamp;
        _strikeHistory[userContract.strike][_strikeToInfos[userContract.strike].updateCount] = _strikeToInfos[userContract.strike];
        _strikeToInfos[userContract.strike].updateCount += 1;

        // Burn the contract token and emit the event
        IERC721x(_ERC721_CONTRACT).burn(_id);
        emit ContractClosed(contractOwner, _id, userContract.amount);        
    }

    /// @notice Liquidates a contract position on behalf of the collateral pool if conditions are met, and burns the contract NFT.
    /// @dev Ensures that only the collateral pool can call this function. Settles the contract based on the current price relative to the strike price.
    /// @param _id The unique ID of the contract to liquidate.
    function liquidateContract(uint256 _id) external {
        require(msg.sender == IMain(_MAIN).getCollateralPool() , "Only Collateral Pool");

        // Get Infos
        ContractInfos memory userContract = _contractIdToInfos[_id];
        address contractOwner = IERC721x(_ERC721_CONTRACT).ownerOf(_id);
        uint256 currentPrice = getPrice();

        // Call or Put ?
        if (userContract.isCall) {

            // if contract ITM, then pay strike x amount and receive amount (token call), else nothing
            if (currentPrice > userContract.strike) {
                IERC20x(_TOKENB).transferFrom(tx.origin, address(this), toTokenBDecimals((userContract.strike * userContract.amount)/1e18));
                IERC20x(_TOKENA).transfer(tx.origin, toTokenADecimals(userContract.amount));
                _strikeToInfos[userContract.strike].callLR += (userContract.strike * userContract.amount)/1e18;
            }

            _strikeToInfos[userContract.strike].callLU -= userContract.amount;

        } else {

            // if contract ITM, then pay amount (token Put) and receive strike x amount, else nothing
            if (currentPrice < userContract.strike) {
                IERC20x(_TOKENA).transferFrom(tx.origin, address(this), toTokenADecimals((userContract.amount * 1e18)/userContract.strike));
                IERC20x(_TOKENB).transfer(tx.origin, toTokenBDecimals(userContract.amount));
                _strikeToInfos[userContract.strike].putLR += (userContract.amount * 1e18)/userContract.strike;
                
            }

            _strikeToInfos[userContract.strike].putLU -= userContract.amount;

        }

        // Update CollateralPool
        ICollateralPool(IMain(_MAIN).getCollateralPool()).updateUserInfos(contractOwner, false, userContract.rent, block.timestamp);

        // Feed Strike History
        _strikeToInfos[userContract.strike].updated = block.timestamp;
        _strikeHistory[userContract.strike][_strikeToInfos[userContract.strike].updateCount] = _strikeToInfos[userContract.strike];
        _strikeToInfos[userContract.strike].updateCount += 1;

        // Burn the contract token and emit the event
        IERC721x(_ERC721_CONTRACT).burn(_id);
        emit ContractClosed(contractOwner, _id, userContract.amount);        
    }

    /// @notice Allows the collateral pool to claim accumulated rewards for a specific liquidity position.
    /// @dev Only callable by the collateral pool. Updates the last claim timestamp for the position.
    /// @param _id The unique ID of the liquidity position for which rewards are claimed.
    /// @return rewards The amount of rewards claimed for the specified position (18 decimals).
    function claimRewards(uint256 _id) external returns(uint256) {
        require(msg.sender == IMain(_MAIN).getCollateralPool() , "Only Collateral Pool");

        // Get Infos
        uint256 rewards = getRewards(_id);

        // Update LP Infos
        _lpIdToInfos[_id].lastClaim = block.timestamp;

        return rewards;
    }
    
}
