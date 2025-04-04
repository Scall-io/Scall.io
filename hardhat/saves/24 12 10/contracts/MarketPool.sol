// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "./ERC721_Enumerable.sol";
import "./interfaces/IChainlink.sol";
import "./interfaces/IERC20x.sol";
import "./interfaces/IERC721x.sol";

import "hardhat/console.sol";

contract MarketPool {

    event Deposit(address indexed user, bool isCall, uint256 amount, uint256 strike, uint256 lpId);
    event Withdraw(address indexed user, uint256 lpId, uint256 amount);
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
    address private _TOKENA; //Asset
    address private _TOKENB; //Base

    //Variable
    address private _PRICEFEED;
    uint256 private _PRICEFEED_DECIMAL;
    uint256 private _RANGE;
    uint256 private _YIELD;
    
    constructor(address _main, address _tokenA, address _tokenB, address _pricefeed, uint256 _pricefeedDecimal, uint256 _range, uint256 _yield) {
        _MAIN = _main;
        _TOKENA = _tokenA;
        _TOKENB = _tokenB;
        
        ERC721_Enumerable erc721_contract = new ERC721_Enumerable("test", "TST");
        _ERC721_CONTRACT = address(erc721_contract);

        ERC721_Enumerable erc721_lp = new ERC721_Enumerable("test", "TST");
        _ERC721_LP = address(erc721_lp);

        _PRICEFEED = _pricefeed;
        _PRICEFEED_DECIMAL = _pricefeedDecimal;
        _RANGE = _range;
        _YIELD = _yield;
    }

    ////////////////////////////////////////////////////////////////// SET UP //////////////////////////////////////////////////////////////////

    struct StrikeInfos {
        uint256 callLP;
        uint256 callLU;
        uint256 putLP;
        uint256 putLU;
    }  

    struct LpInfos {
        bool isCall;
        uint256 strike;
        uint256 amount;
        uint256 start;
        uint256 lastClaim;
        uint256 rewards;
    }  

    struct ContractInfos {
        bool isCall;
        uint256 strike;
        uint256 amount;
        uint256 rent;
        uint256 start;
    }

    mapping(uint256 => LpInfos) private LpIdToInfos;
    mapping(uint256 => ContractInfos) private ContractIdToInfos;
    //mapping(uint256 => StrikeInfos) private StrikeToInfos;


    ////////////////////////////////////////////////////////////////// BASE FUNCTIONS //////////////////////////////////////////////////////////////////

    function getMain() public view returns(address) {
        return _MAIN;
    }

    function getERC721_Contract() public view returns(address) {
        return _ERC721_CONTRACT;
    }

    function getERC721_LP() public view returns(address) {
        return _ERC721_LP;
    }

    function getTokenA() public view returns(address) {
        return _TOKENA;
    }

    function getTokenB() public view returns(address) {
        return _TOKENB;
    }

    function getPriceFeed() public view returns(address) {
        return _PRICEFEED;
    }

    function getRange() public view returns(uint256) {
        return _RANGE;
    }

    function getYield() public view returns(uint256) {
        return _YIELD;
    }

    function getContractInfos(uint256 _id) public view returns(ContractInfos memory) {
        return ContractIdToInfos[_id];
    }

    function getLpInfos(uint256 _id) public view returns(LpInfos memory) {
        return LpIdToInfos[_id];        
    }

    function setPriceFeed(address _priceFeed, uint256 _decimal) public {
        _PRICEFEED = _priceFeed;
        _PRICEFEED_DECIMAL = _decimal;
    }

    function setRange(uint256 _range) public {
        _RANGE = _range;
    }

    function setYield(uint256 _yield) public {
        _YIELD = _yield;
    } 

    ////////////////////////////////////////////////////////////////// GET FUNCTIONS //////////////////////////////////////////////////////////////////

    function getPrice() public view returns(uint256) {
        (, int result,,,) = IChainlink(_PRICEFEED).latestRoundData();
        return uint256(result) * (1e18/10**_PRICEFEED_DECIMAL);
    }

    function getInterval() public view returns(uint256[2] memory){
        uint256 currentPrice = getPrice();

        uint256 modulo = currentPrice % _RANGE;

        uint256 lowerBound = currentPrice - modulo;
        uint256 upperBound = lowerBound + _RANGE;

        return [lowerBound, upperBound];
    }

    function getStrikeInfos() public view returns(StrikeInfos memory) {
        LpInfos memory thisLP;
        ContractInfos memory thisContract;
        uint256 ID;
        uint256 callLP;
        uint256 callLU;
        uint256 putLP;
        uint256 putLU;
        uint256 totalSupplyLP = IERC721x(_ERC721_LP).totalSupply();
        uint256 totalSupplyContract = IERC721x(_ERC721_CONTRACT).totalSupply();

        //For all open LP
        for (uint256 i ; i < totalSupplyLP ; i++) {
            ID = IERC721x(_ERC721_LP).tokenByIndex(i);
            thisLP = LpIdToInfos[ID];

            //if call then add callLP else add to putLP
            if(thisLP.isCall) {
                callLP += thisLP.amount;
            } else {
                putLP += thisLP.amount;
            }
        }

        //For all open trade
        for (uint256 ii ; ii < totalSupplyContract ; ii++) {
            ID = IERC721x(_ERC721_CONTRACT).tokenByIndex(ii);
            thisContract = ContractIdToInfos[ID];

            //if call then add callLU else add to putLU
            if(thisContract.isCall) {
                callLU += thisContract.amount;
            } else {
                putLU += thisContract.amount;
            }
        }

        return StrikeInfos(callLP, callLU, putLP, putLU);
    }

    ////////////////////////////////////////////////////////////////// USERS FUNCTIONS //////////////////////////////////////////////////////////////////

    function deposit(bool _isCall, uint256 _amount) public {

        //Get Interval
        uint256[2] memory interval = getInterval();
        uint256 strike;

        // Transfer token and get Strike
        if (_isCall) {
            IERC20x(_TOKENA).transferFrom(msg.sender, address(this), _amount);
            strike = interval[1];
        } else {
            IERC20x(_TOKENB).transferFrom(msg.sender, address(this), _amount);
            strike = interval[0];
        }        

        //Set Lp position
        LpInfos memory newLP = LpInfos(_isCall, strike, _amount, block.timestamp, block.timestamp, 0);
        LpIdToInfos[_lpCount] = newLP;
        IERC721x(_ERC721_LP).mint(msg.sender, _lpCount);

        // Emit the deposit event
        emit Deposit(msg.sender, _isCall, _amount, strike, _lpCount);

        _lpCount++;        
    }

    function withdraw(uint256 _id) public {
        StrikeInfos memory strikeInfos = getStrikeInfos();
        LpInfos memory thisLP = LpIdToInfos[_id];
        uint256 availableFunds;

        //Call or Put ?
        if (thisLP.isCall) {
            availableFunds = strikeInfos.callLP - strikeInfos.callLU;

            // if available funds inferior to lp => send available funds and update lpinfos, else => send lp amount and burn id
            if (availableFunds < thisLP.amount) {
                IERC20x(_TOKENA).transfer(msg.sender, availableFunds);
                LpIdToInfos[_id].amount -= availableFunds;
            } else {
                IERC20x(_TOKENA).transfer(msg.sender, thisLP.amount);
                IERC721x(_ERC721_LP).burn(_id);
            }

        } else {
            availableFunds = strikeInfos.putLP - strikeInfos.putLU;

            // if available funds inferior to lp => send available funds and update lpinfos, else => send lp amount and burn id
            if (availableFunds < thisLP.amount) {
                IERC20x(_TOKENB).transfer(msg.sender, availableFunds);
                LpIdToInfos[_id].amount -= availableFunds;
            } else {
                IERC20x(_TOKENB).transfer(msg.sender, thisLP.amount);
                IERC721x(_ERC721_LP).burn(_id);
            }

        }

        // Emit the withdrawal event
        emit Withdraw(msg.sender, _id, availableFunds);                
    }

    function openContract(bool _isCall, uint256 _amount) public {

        //Get Interval
        uint256[2] memory interval = getInterval();

        //Get Strike
        uint256 strike;
        if (_isCall == true) {
            strike = interval[1];
        } else {
            strike = interval[0];
        }

        //Get Premium
        uint256 rent = ((((_amount*strike)/1e18)*_YIELD)/1e18)/31536000;

        //Set Contract
        ContractInfos memory newContract = ContractInfos(_isCall, strike, _amount, rent, block.timestamp);
        ContractIdToInfos[_contractCount] = newContract;
        IERC721x(_ERC721_CONTRACT).mint(msg.sender, _contractCount);

        // Emit the contract opened event
        emit ContractOpened(msg.sender, _isCall, _amount, strike, _contractCount);

        _contractCount++;
    }

    function closeContract(uint256 _id) public {

        ContractInfos memory userContract = ContractIdToInfos[_id];
        uint256 currentPrice = getPrice();

        //Call or Put ?
        if (userContract.isCall) {

            //if contract ITM, then pay strike x amount and receive amount (token call), else nothing
            if (currentPrice > userContract.strike) {
                IERC20x(_TOKENB).transferFrom(msg.sender, address(this), (userContract.strike * userContract.amount)/1e18);
                IERC20x(_TOKENA).transfer(msg.sender, userContract.amount);                
            }

        } else {

            //if contract ITM, then pay amount (token Put) and receive strike x amount, else nothing
            if (currentPrice < userContract.strike) {
                IERC20x(_TOKENA).transferFrom(msg.sender, address(this), userContract.amount);
                IERC20x(_TOKENB).transfer(msg.sender, (userContract.strike * userContract.amount)/1e18);                
            }

        }

        // Burn the contract token and emit the event
        IERC721x(_ERC721_CONTRACT).burn(_id);
        emit ContractClosed(msg.sender, _id, userContract.amount);        
    }
    
}
