const { expect } = require("chai");
const { ethers } = require("hardhat");
const { mine } = require("@nomicfoundation/hardhat-network-helpers");

/* global BigInt */

describe("POP", function () {


  let USDC = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  let WETH = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
  let WBTC = "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6";

  let owner;
  let addr1;
  let addr2;
  let addr3;

  let Main;
  let main;

  let MarketPool;
  let marketPoolBTC;
  let marketPoolETH;

  let CollateralPool;
  let collateralPool;

  let fakeTokenContract;
  let fakeUSDC;
  let fakeWETH;
  let fakeWBTC;

  let FakeOracle;
  let fakeEthOracle;
  let fakeBtcOracle;

  let wethContract;
  let wbtcContract;
  let usdcContract;

  let rewardsClaimed;
  let feesClaimed;

  describe("Initialization", function() {

    it("Should initialize accounts", async function() {
      [owner, addr1, addr2, addr3] = await ethers.getSigners();
    });

    it("Should create fake tokens", async function() {
  
      fakeTokenContract = await ethers.getContractFactory("fakeToken");
      fakeUSDC = await fakeTokenContract.deploy("fakeUSDC", "fUSDC", 6);
      fakeWETH = await fakeTokenContract.deploy("fakeWETH", "fWETH", 18);
      fakeWBTC = await fakeTokenContract.deploy("fakeWBTC", "fWBTC", 8);

      await fakeUSDC.transfer(addr1.address, BigInt(10000000e18));
      await fakeWBTC.transfer(addr1.address, BigInt(10000e18));
      await fakeWETH.transfer(addr1.address, BigInt(10000e18));

      await fakeUSDC.transfer(addr2.address, BigInt(10000000e18));
      await fakeWBTC.transfer(addr2.address, BigInt(10000e18));
      await fakeWETH.transfer(addr2.address, BigInt(10000e18));

      await fakeUSDC.transfer(addr3.address, BigInt(10000000e18));
      await fakeWBTC.transfer(addr3.address, BigInt(10000e18));
      await fakeWETH.transfer(addr3.address, BigInt(10000e18));
  
    })


    it("Should deploy Fakeoracles", async function() {
    
      FakeOracle = await ethers.getContractFactory("fakeOracle");
      fakeEthOracle = await FakeOracle.deploy();
      fakeBtcOracle = await FakeOracle.deploy();

      await fakeEthOracle.setPrice(BigInt(2500e8));
      await fakeBtcOracle.setPrice(BigInt(95300e8));
    
    })
    
    it("Should create contracts", async function() {

      Main = await ethers.getContractFactory("Main");
      main = await Main.deploy(fakeUSDC.target, 6);
  
      CollateralPool = await ethers.getContractFactory("CollateralPool");
      collateralPool = await CollateralPool.deploy(fakeUSDC, 6, main.target);
      
      Dashboard = await ethers.getContractFactory("Dashboard");
      dashboard = await Dashboard.deploy(main.target);
  
    })

    it("Should initialize Main", async function() {

      await main.setCollateralPool(collateralPool.target);
  
    })
      
    it("Should create the market WBTC/USDC and WETH/USDC", async function() {
  
      MarketPool = await ethers.getContractFactory("MarketPool");
      marketPoolBTC = await MarketPool.deploy(main.target, fakeWBTC, 8, fakeUSDC, 6, fakeBtcOracle.target, 8, BigInt(1000e18), BigInt(20e16));
      marketPoolETH = await MarketPool.deploy(main.target, fakeWETH, 18, fakeUSDC, 6, fakeEthOracle.target, 8, BigInt(50e18), BigInt(20e16));
  
    })

    it("Should link market to Main", async function() {
  
      await main.linkMarket(marketPoolBTC.target);
      await main.linkMarket(marketPoolETH.target);
  
    })

    it("Should do all approvals", async function() {
  
      await fakeUSDC.approve(collateralPool.target, BigInt(1000000000e18));
      await fakeUSDC.approve(marketPoolBTC.target, BigInt(1000000000e18));
      await fakeWBTC.approve(marketPoolBTC.target, BigInt(1000000000e18));
      await fakeUSDC.approve(marketPoolETH.target, BigInt(1000000000e18));
      await fakeWBTC.approve(marketPoolETH.target, BigInt(1000000000e18));


      await fakeUSDC.connect(addr1).approve(collateralPool.target, BigInt(1000000000e18));
      await fakeUSDC.connect(addr1).approve(marketPoolBTC.target, BigInt(1000000000e18));
      await fakeWBTC.connect(addr1).approve(marketPoolBTC.target, BigInt(1000000000e18));
      await fakeUSDC.connect(addr1).approve(marketPoolETH.target, BigInt(1000000000e18));
      await fakeWETH.connect(addr1).approve(marketPoolETH.target, BigInt(1000000000e18));

      await fakeUSDC.connect(addr2).approve(collateralPool.target, BigInt(1000000000e18));
      await fakeUSDC.connect(addr2).approve(marketPoolBTC.target, BigInt(1000000000e18));
      await fakeWBTC.connect(addr2).approve(marketPoolBTC.target, BigInt(1000000000e18));
      await fakeUSDC.connect(addr2).approve(marketPoolETH.target, BigInt(1000000000e18));
      await fakeWETH.connect(addr2).approve(marketPoolETH.target, BigInt(1000000000e18));

      await fakeUSDC.connect(addr3).approve(collateralPool.target, BigInt(1000000000e18));
      await fakeUSDC.connect(addr3).approve(marketPoolBTC.target, BigInt(1000000000e18));
      await fakeWBTC.connect(addr3).approve(marketPoolBTC.target, BigInt(1000000000e18));
      await fakeUSDC.connect(addr3).approve(marketPoolETH.target, BigInt(1000000000e18));
      await fakeWETH.connect(addr3).approve(marketPoolETH.target, BigInt(1000000000e18));
  
    })

  });

  describe("Test Functions", function() {
    it("Should give oracle prices", async function() {
      tx = await marketPoolBTC.getPrice();
      console.log("BTC current price : "+tx/BigInt(1e18));
    })

    it("Should give oracle prices", async function() {
        tx = await marketPoolETH.getPrice();
        console.log("ETH current price : "+tx/BigInt(1e18));
    })

  });

  describe("LPs :: Check BTC", function() {

    it("Should deposit call LP at correct interval for Owner and addr1", async function() {
      let strikeValue = BigInt("97000000000000000000000");
      tx = await marketPoolBTC.getStrikeInfos(strikeValue);
      console.log(tx);

      tx = await marketPoolBTC.deposit(true, BigInt(4e8));
      tx = await marketPoolBTC.connect(addr1).deposit(true, BigInt(3e8));

      tx = await marketPoolBTC.getStrikeInfos(strikeValue);
      console.log(tx);
    })
    
  })

  describe("Trades :: Check BTC", function() {

    it("Should deposit collateral for addr2", async function() {
      tx = await collateralPool.getUserInfos(addr2.address);
      console.log("UserInfos Before : "+tx);
      
      await collateralPool.connect(addr2).depositCollateral(BigInt(15000e6));

      tx = await collateralPool.getUserInfos(addr2.address);
      console.log("UserInfos After : "+tx);
    })

    it("Should open a trade for addr2", async function() {
      let strikeValue = BigInt("97000000000000000000000");
      tx = await marketPoolBTC.getStrikeInfos(strikeValue);
      console.log("StrikeInfos Before : "+tx);

      await marketPoolBTC.connect(addr2).openContract(true, BigInt(5e8));

      tx = await marketPoolBTC.getStrikeInfos(strikeValue);
      console.log("StrikekInfos After : "+tx);
      tx = await collateralPool.getUserInfos(addr2.address);
      console.log("UserInfos After : "+tx);
    })

  })

  describe("LPs :: Check ETH", function() {

    it("Should deposit call LP at correct interval for Owner and addr1", async function() {
      let strikeValue = BigInt("2600000000000000000000");
      tx = await marketPoolETH.getStrikeInfos(strikeValue);
      console.log(tx);

      let amountValue = BigInt("20000000000");
      tx = await marketPoolETH.connect(addr1).deposit(true, BigInt(11e18));
      tx = await marketPoolETH.connect(addr1).deposit(false, amountValue);

      tx = await marketPoolETH.getStrikeInfos(strikeValue);
      console.log(tx);
    })
    
  })

  describe("Trades :: Check ETH", function() {

    it("Should open a trade for addr2", async function() {
      let strikeValue = BigInt("2600000000000000000000");
      tx = await marketPoolETH.getStrikeInfos(strikeValue);
      console.log("StrikeInfos Before : "+tx);

      await marketPoolETH.connect(addr2).openContract(true, BigInt(7e18));

      tx = await marketPoolETH.getStrikeInfos(strikeValue);
      console.log("StrikekInfos After : "+tx);
      tx = await collateralPool.getUserInfos(addr2.address);
      console.log("UserInfos After : "+tx);
    })

    it("Should deposit collateral for addr3", async function() {
      tx = await collateralPool.getUserInfos(addr3.address);
      console.log("UserInfos Before : "+tx);
      
      await collateralPool.connect(addr3).depositCollateral(BigInt(1000e6));

      tx = await collateralPool.getUserInfos(addr3.address);
      console.log("UserInfos After : "+tx);
    })

    it("Should open a trade for addr3", async function() {
      let strikeValue = BigInt("2450000000000000000000");
      tx = await marketPoolETH.getStrikeInfos(strikeValue);
      console.log("StrikeInfos Before : "+tx);

      let amountValue = BigInt("8600000000");
      await marketPoolETH.connect(addr3).openContract(false, amountValue);

      tx = await marketPoolETH.getStrikeInfos(strikeValue);
      console.log("StrikekInfos After : "+tx);
      tx = await collateralPool.getUserInfos(addr3.address);
      console.log("UserInfos After : "+tx);
    })

  })

  describe("Trades :: Check Dashboard", function() {

    it("Should give all users Address", async function() {
      tx = await dashboard.getAllUsers();
      console.log(tx);
    })

    it("Should give all LPs Address", async function() {
      tx = await dashboard.getAllLps();
      console.log(tx);
    })

    it("Should give Collateral Pool Balance Details", async function() {
      tx = await dashboard.getCollateralPoolBalanceDetail();
      console.log(tx);
    })

    it("Should give market's total OI", async function() {
      tx = await dashboard.getMarketOpenInterest(1);
      console.log(tx);
    })

    it("Should give market's total Liquidity Provided", async function() {
      tx = await dashboard.getMarketLiquidityProvided(1);
      console.log(tx);
    })

    it("Should give market's available liquidation", async function() {
      tx = await dashboard.getMarketAvailableLiquidation(1);
      console.log(tx);
    })

    it("Should give market's addr1 LP infos", async function() {
      tx = await dashboard.getUserLpInfosForMarket(1, addr1.address);
      console.log(tx);
    })

    it("Should give market's balance detail", async function() {
      tx = await dashboard.getMarketBalanceDetail(1);
      console.log(tx);
    })

  })

  describe("Time :: Change", function() {

    it("should change block and timestamp", async function() {
      await mine(86400);
      console.log("...1 days")
    })

  });

  describe("Oracles :: Prices moove", function() {

    it("should moove the prices", async function() {
      await fakeEthOracle.setPrice(BigInt(2725e8));
      tx = await marketPoolETH.getPrice();
      console.log("Current price : "+tx/BigInt(1e18));
    })

    it("should moove the prices", async function() {
      await fakeBtcOracle.setPrice(BigInt(99250e8));
      tx = await marketPoolBTC.getPrice();
      console.log("Current price : "+tx/BigInt(1e18));
    })

  });

  describe("Trades :: Check", function() {

    it("Should exercise contract 2", async function() {
      let balanceBTCAV = await fakeWETH.balanceOf(addr2.address);
      let balanceUSDCAV = await fakeUSDC.balanceOf(addr2.address);

      tx = await collateralPool.getUserFees(addr2.address);
      console.log("Fees paid : "+tx/BigInt(1e18));
      feesClaimed = tx;

      await marketPoolETH.connect(addr2).closeContract(0);
      let balanceBTCAP = await fakeWETH.balanceOf(addr2.address);
      let balanceUSDCAP = await fakeUSDC.balanceOf(addr2.address);
      console.log("Balance WETH change: "+(balanceBTCAP - balanceBTCAV)/BigInt(1e18));
      console.log("Balance USDC change: "+(balanceUSDCAP - balanceUSDCAV)/BigInt(1e6));
    })

  })

  describe("Time :: Change", function() {

    it("should change block and timestamp", async function() {
      await mine(86400);
      console.log("...1 days")
    })

  });

  describe("Oracles :: Prices moove", function() {

    it("should moove the prices", async function() {
      await fakeEthOracle.setPrice(BigInt(2050e8));
      tx = await marketPoolETH.getPrice();
      console.log("Current price : "+tx/BigInt(1e18));
    })

  });

  describe("Trades :: Check", function() {

    it("Should exercise contract 3", async function() {
      let balanceBTCAV = await fakeWETH.balanceOf(addr3.address);
      let balanceUSDCAV = await fakeUSDC.balanceOf(addr3.address);

      tx = await collateralPool.getUserFees(addr3.address);
      console.log("Fees paid : "+tx/BigInt(1e18));
      feesClaimed += tx;

      await marketPoolETH.connect(addr3).closeContract(1);
      let balanceBTCAP = await fakeWETH.balanceOf(addr3.address);
      let balanceUSDCAP = await fakeUSDC.balanceOf(addr3.address);
      console.log("Balance WETH change: "+(balanceBTCAP - balanceBTCAV)/BigInt(1e18));
      console.log("Balance USDC change: "+(balanceUSDCAP - balanceUSDCAV)/BigInt(1e6));
    })

  })

  describe("LPs :: Check BTC", function() {

    it("Should claim fees for addr1", async function() {
      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner call : "+tx/BigInt(1e18));
  
      rewardsClaimed = BigInt(tx);
  
      let balanceAV = await fakeUSDC.balanceOf(owner.address);
      await collateralPool.claimRewards(0, 0);
      let balanceAP = await fakeUSDC.balanceOf(owner.address);
      console.log(balanceAP - balanceAV);
    
    })

    it("Should claim fees for addr1", async function() {
      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr1 call : "+tx/BigInt(1e18));
  
      rewardsClaimed += BigInt(tx);
  
      let balanceAV = await fakeUSDC.balanceOf(addr1.address);
      await collateralPool.connect(addr1).claimRewards(0, 1);
      let balanceAP = await fakeUSDC.balanceOf(addr1.address);
      console.log(balanceAP - balanceAV);
    
    })

  })

  describe("LPs :: Check ETH", function() {

    it("Should claim fees for addr1", async function() {
      tx = await collateralPool.getRewardsForLp(1, 0);
      console.log("rewards for addr1 call : "+tx/BigInt(1e18));
  
      rewardsClaimed += BigInt(tx);
  
      let balanceAV = await fakeUSDC.balanceOf(addr1.address);
      await collateralPool.connect(addr1).claimRewards(1, 0);
      let balanceAP = await fakeUSDC.balanceOf(addr1.address);
      console.log(balanceAP - balanceAV);

      tx = await collateralPool.getRewardsForLp(1, 1);
      console.log("rewards for addr1 put : "+tx/BigInt(1e18));
  
      rewardsClaimed += BigInt(tx);
  
      balanceAV = await fakeUSDC.balanceOf(addr1.address);
      await collateralPool.connect(addr1).claimRewards(1, 1);
      balanceAP = await fakeUSDC.balanceOf(addr1.address);
      console.log(balanceAP - balanceAV);
    
    })

  })

  describe("Trades :: Check aaaaaaaaaaaaaaaaaaaaaa", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner BTC call : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 BTC call : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(1, 0);
      console.log("rewards for addr1 ETH call : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(1, 1);
      console.log("rewards for addr1 ETH put : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Paid : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr2.address);
      console.log("Addr2 fees USDC : "+tx/BigInt(1e18));

      tx = await collateralPool.getUserFees(addr3.address);
      console.log("Addr3 fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Trades :: Check Dashboard", function() {

    it("Should give all users Address", async function() {
      tx = await dashboard.getAllUsers();
      console.log(tx);
    })

    it("Should give all LPs Address", async function() {
      tx = await dashboard.getAllLps();
      console.log(tx);
    })

    it("Should give Collateral Pool Balance Details", async function() {
      tx = await dashboard.getCollateralPoolBalanceDetail();
      console.log(tx);
    })

    it("Should give market's total OI", async function() {
      tx = await dashboard.getMarketOpenInterest(1);
      console.log(tx);
    })

    it("Should give market's total Liquidity Provided", async function() {
      tx = await dashboard.getMarketLiquidityProvided(1);
      console.log(tx);
    })

    it("Should give market's available liquidation", async function() {
      tx = await dashboard.getMarketAvailableLiquidation(1);
      console.log(tx);
    })

    it("Should give market's owner LP infos", async function() {
      tx = await dashboard.getUserLpInfosForMarket(1, owner.address);
      console.log(tx);
    })

    it("Should give market's addr2 LP infos", async function() {
      tx = await dashboard.getUserLpInfosForMarket(1, addr1.address);
      console.log(tx);
    })

    it("Should give market's balance detail", async function() {
      tx = await dashboard.getMarketBalanceDetail(1);
      console.log(tx);
    })

  })

  describe("Trades :: Check", function() {

    it("Should give addr1 fees", async function() {
      tx = await collateralPool.getUserFees(addr2.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

    it("Should give addr1 infos", async function() {
      tx = await collateralPool.getUserInfos(addr2.address);
      console.log("Trader Infos : "+tx);
    })

    it("Should give addr1 balance", async function() {
      tx = await collateralPool.balanceOf(addr2.address);
      console.log("Trader balance USDC : "+tx/BigInt(1e18));
    })

    it("Should say if need to liquidiate addr1", async function() {
      tx = await collateralPool.needLiquidation(addr2.address);
      console.log("Trader need liquidation : "+tx);
    })

  })

  describe("Trades :: Check ETH", function() {

    it("Should open a trade for addr2", async function() {
      let strikeValue = BigInt("2000000000000000000000");
      tx = await marketPoolETH.getStrikeInfos(strikeValue);
      console.log("StrikeInfos Before : "+tx);

      let amountValue = BigInt("21000000000");
      tx = await marketPoolETH.connect(addr1).deposit(true, BigInt(20e18));
      tx = await marketPoolETH.connect(addr1).deposit(false, amountValue);

      amountValue = BigInt("8400000000");
      await marketPoolETH.connect(addr2).openContract(false, amountValue);
      await marketPoolETH.connect(addr2).openContract(false, amountValue);

      tx = await marketPoolETH.getStrikeInfos(strikeValue);
      console.log("StrikekInfos After : "+tx);
      tx = await collateralPool.getUserInfos(addr2.address);
      console.log("UserInfos After : "+tx);
    })

  })

  describe("Information ETH Market", function() {

    it("should change give me contract informations", async function() {
      tx = await marketPoolETH.getContractInfos(0);
      console.log(tx);

      tx = await marketPoolETH.getContractInfos(1);
      console.log(tx);

      tx = await marketPoolETH.getContractInfos(2);
      console.log(tx);
    })

  });

  describe("Time :: Change", function() {

    it("should change block and timestamp", async function() {
      await mine(1730000);
      console.log("...20 days")
    })

  });

  describe("Oracles :: Prices moove", function() {

    it("should moove the prices", async function() {
      await fakeEthOracle.setPrice(BigInt(2400e8));
      tx = await marketPoolETH.getPrice();
      console.log("Current price : "+tx/BigInt(1e18));
    })

  });

  describe("Trades :: Check", function() {

    it("should change give me contract informations", async function() {
      let strikeValue = BigInt("2000000000000000000000");
      tx = await marketPoolETH.getStrikeInfos(strikeValue);
      console.log("StrikeInfos Before : "+tx);
    })

    it("Should exercise contract", async function() {
      let balanceBTCAV = await fakeWETH.balanceOf(addr2.address);
      let balanceUSDCAV = await fakeUSDC.balanceOf(addr2.address);
      console.log(balanceUSDCAV);

      tx = await collateralPool.getUserFees(addr2.address);
      console.log("Fees claimed : "+tx/BigInt(1e18));
      feesClaimed += tx;

      await marketPoolETH.connect(addr2).closeContract(2);
      let balanceBTCAP = await fakeWETH.balanceOf(addr2.address);
      let balanceUSDCAP = await fakeUSDC.balanceOf(addr2.address);
      console.log(balanceUSDCAP);
      console.log("Balance WETH change: "+(balanceBTCAP - balanceBTCAV)/BigInt(1e18));
      console.log("Balance USDC change: "+(balanceUSDCAP - balanceUSDCAV)/BigInt(1e18));
    })

    it("should change give me contract informations", async function() {
      let strikeValue = BigInt("2000000000000000000000");
      tx = await marketPoolETH.getStrikeInfos(strikeValue);
      console.log("StrikeInfos After : "+tx);
    })

  })

  describe("Time :: Change", function() {

    it("should change block and timestamp", async function() {
      await mine(173000);
      console.log("...2 days")
    })

  });

  describe("Oracles :: Prices moove", function() {

    it("should moove the prices", async function() {
      await fakeEthOracle.setPrice(BigInt(1800e8));
      tx = await marketPoolETH.getPrice();
      console.log("Current price : "+tx/BigInt(1e18));
    })

  });

  describe("Trades :: Check", function() {

    it("Should exercise contract", async function() {
      let balanceBTCAV = await fakeWETH.balanceOf(addr2.address);
      let balanceUSDCAV = await fakeUSDC.balanceOf(addr2.address);

      tx = await collateralPool.getUserFees(addr2.address);
      console.log("Fees claimed : "+tx/BigInt(1e18));
      feesClaimed += tx;

      await marketPoolETH.connect(addr2).closeContract(3);
      let balanceBTCAP = await fakeWETH.balanceOf(addr2.address);
      let balanceUSDCAP = await fakeUSDC.balanceOf(addr2.address);
      console.log("Balance WETH change: "+(balanceBTCAP - balanceBTCAV)/BigInt(1e18));
      console.log("Balance USDC change: "+(balanceUSDCAP - balanceUSDCAV)/BigInt(1e6));
    })

  })

  describe("Trades :: Check Dashboard", function() {

    it("Should give all users Address", async function() {
      tx = await dashboard.getAllUsers();
      console.log(tx);
    })

    it("Should give all LPs Address", async function() {
      tx = await dashboard.getAllLps();
      console.log(tx);
    })

    it("Should give Collateral Pool Balance Details", async function() {
      tx = await collateralPool.balanceOf("0x90F79bf6EB2c4f870365E785982E1f101E93b906");
      console.log(tx);

      tx = await dashboard.getCollateralPoolBalanceDetail();
      console.log(tx);
    })

    it("Should give market's total OI", async function() {
      tx = await dashboard.getMarketOpenInterest(1);
      console.log(tx);
    })

    it("Should give market's total Liquidity Provided", async function() {
      tx = await dashboard.getMarketLiquidityProvided(1);
      console.log(tx);
    })

    it("Should give market's available liquidation", async function() {
      tx = await dashboard.getMarketAvailableLiquidation(1);
      console.log(tx);
    })

    it("Should give market's owner LP infos", async function() {
      tx = await dashboard.getUserLpInfosForMarket(1, owner.address);
      console.log(tx);
    })

    it("Should give market's addr2 LP infos", async function() {
      tx = await dashboard.getUserLpInfosForMarket(1, addr1.address);
      console.log(tx);
    })

    it("Should give market's balance detail", async function() {
      tx = await dashboard.getMarketBalanceDetail(1);
      console.log(tx);
    })

  })

  describe("Time :: Change", function() {

    it("should change block and timestamp", async function() {
      await mine(2592000);
      console.log("...30 days")
    })

  });

  describe("CollateralPool :: Check", function() {

    it("should give collateral balance of user", async function() {
      tx = await collateralPool.balanceOf(addr2.address);
      console.log(tx/BigInt(1e18));
    })

    it("should tell if user need liquidation", async function() {
      tx = await collateralPool.needLiquidation(addr2.address);
      console.log(tx);
    })

    it("should liquidate the contract", async function() {

      let balanceBTCAV = await fakeWBTC.balanceOf(owner.address);
      let balanceAV = await fakeUSDC.balanceOf(owner.address);
      tx = await collateralPool.liquidateContract(addr2.address, 0, 0);
      let balanceAP = await fakeUSDC.balanceOf(owner.address);
      let balanceBTCAP = await fakeWBTC.balanceOf(owner.address);

      console.log("USDC Ajouté à la balance : "+((balanceAP-balanceAV)/BigInt(1e6)));
      console.log("BTC Ajouté à la balance : "+((balanceBTCAP-balanceBTCAV)/BigInt(1e8)));
      
    })

  });
  
});