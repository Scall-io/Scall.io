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

  let Main;
  let main;

  let MarketPool;
  let marketPool;

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

  describe("Initialization", function() {

    it("Should initialize accounts", async function() {
      [owner, addr1, addr2] = await ethers.getSigners();
    });

    it("Should create fake tokens", async function() {
  
      fakeTokenContract = await ethers.getContractFactory("fakeToken");
      fakeUSDC = await fakeTokenContract.deploy("fakeUSDC", "fUSDC");
      fakeWETH = await fakeTokenContract.deploy("fakeWETH", "fWETH");
      fakeWBTC = await fakeTokenContract.deploy("fakeWBTC", "fWBTC");

      await fakeUSDC.transfer(addr1.address, BigInt(10000000e18));
      await fakeWBTC.transfer(addr1.address, BigInt(10000e18));
  
    })


    it("Should deploy Fakeoracles", async function() {
    
      FakeOracle = await ethers.getContractFactory("fakeOracle");
      fakeEthOracle = await FakeOracle.deploy();
      fakeBtcOracle = await FakeOracle.deploy();

      await fakeEthOracle.setPrice(BigInt(2200e8));
      await fakeBtcOracle.setPrice(BigInt(52500e8));
    
    })
    
    it("Should create contracts", async function() {

      Main = await ethers.getContractFactory("Main");
      main = await Main.deploy();
  
      CollateralPool = await ethers.getContractFactory("CollateralPool");
      collateralPool = await CollateralPool.deploy(fakeUSDC, main.target);      
  
    })

    it("Should initialize Main", async function() {

      await main.setCollateralPool(collateralPool.target);
  
    })
      
    it("Should create the market WBTC/USDC", async function() {
  
      MarketPool = await ethers.getContractFactory("MarketPool");
      marketPool = await MarketPool.deploy(main.target, fakeWBTC, fakeUSDC, fakeBtcOracle.target, 8, BigInt(1000e18), BigInt(20e16));
  
    })

    it("Should link market to Main", async function() {
  
      await main.linkMarket(marketPool.target);
  
    })

    it("Should do all approvals", async function() {
  
      await fakeUSDC.approve(collateralPool.target, BigInt(1000000000e18));
      await fakeUSDC.approve(marketPool.target, BigInt(1000000000e18));
      await fakeWBTC.approve(marketPool.target, BigInt(1000000000e18));

      await fakeUSDC.connect(addr1).approve(collateralPool.target, BigInt(1000000000e18));
      await fakeWBTC.connect(addr1).approve(marketPool.target, BigInt(1000000000e18));

      await fakeUSDC.connect(addr2).approve(collateralPool.target, BigInt(1000000000e18));
      await fakeWBTC.connect(addr2).approve(marketPool.target, BigInt(1000000000e18));
  
    })

  });

  describe("Test Functions", function() {
    it("Should give oracle prices", async function() {
  
      tx = await marketPool.getPrice();
      console.log("Current price : "+tx/BigInt(1e18));
  
    })

  });

  describe("LPs :: Check", function() {

    it("Should deposit call LP at correct interval", async function() {
      tx = await marketPool.deposit(true, BigInt(2e18));
    })

  })

  describe("Trade :: Check", function() {

    it("should deposit collateral", async function() {
      await collateralPool.connect(addr1).depositCollateral(BigInt(1000000e18));
    })

    it("addr1 should create a contrat", async function() {
      await marketPool.connect(addr1).openContract(true, BigInt(1e18));
    })
    
    it("should give user pending fees", async function() {
      tx = await collateralPool.connect(addr1).getFeesFromUser(addr1.address);
      console.log(tx/BigInt(1e18));
    })

  })

  describe("Time :: Change", function() {

    it("should change block and timestamp => 2 days", async function() {
      await mine(86400);
      console.log("...1 days")
    })

  });

  describe("CollateralPool :: Check", function() {

    it("should give user pending fees", async function() {
      tx = await collateralPool.getFeesFromUser(addr1.address);
      console.log(tx/BigInt(1e18));
    })

    it("should give user current balance", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log(tx/BigInt(1e18));
    })

    it("should give lp share for a specific strike in a specific market", async function() {
      let strikeValue = BigInt("53000000000000000000000"); //ça ne marche pas si je met "53000e18"
      tx = await collateralPool.getLpsSharePerStrikeForMarket(strikeValue, 0, 0, true);
      console.log(tx/BigInt(1e18));
      
    })

    it("should give user current balance", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log(tx/BigInt(1e18));
    })

    it("should update the rewards balance, then give us the new user's reward", async function() {
      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log(tx/BigInt(1e18));

      await collateralPool.updateRewards();      

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log(tx/BigInt(1e18));
    })

    it("should give user current balance", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log(tx/BigInt(1e18));
    })

    it("LP should claim rewards", async function() {

      let balanceAV = await fakeUSDC.balanceOf(owner.address);
      await collateralPool.claim(0, 0);
      let balanceAP = await fakeUSDC.balanceOf(owner.address);

      console.log(balanceAP - balanceAV);

    })

  })

  describe("MarketPool :: Check", function() {

    it("should give strike info", async function() {

      tx = await marketPool.getStrikeInfos();
      console.log(tx);
      
    })

    it("should try to withdraw", async function() {

      tx = await marketPool.getLpInfos(0);
      console.log("LP Amount AV : "+tx[2]/BigInt(1e18));
      let balanceAV = await fakeWBTC.balanceOf(owner.address);

      tx = await marketPool.withdraw(0);

      tx = await marketPool.getLpInfos(0);
      console.log("LP Amount AP : "+tx[2]/BigInt(1e18));
      let balanceAP = await fakeWBTC.balanceOf(owner.address);
      console.log("Ajouté à la balance : "+((balanceAP-balanceAV)/BigInt(1e18)));
      
    })

    it("should close Contract", async function() {

      tx = await marketPool.connect(addr1).closeContract(0);     
      
    })

  });

  describe("CollateralPool :: Check", function() {

    it("should open new Contract", async function() {

      tx = await marketPool.connect(addr1).openContract(true, BigInt(1e18));     
      
    })

    it("should give collateral balance of user", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log(tx/BigInt(1e18));
    })

    it("should tell if user need liquidation", async function() {
      tx = await collateralPool.needLiquidation(addr1.address);
      console.log(tx);
    })

    it("should withdraw collateral", async function() {
      tx = await collateralPool.connect(addr1).withdrawCollateral(BigInt(100000e18));
    })

    it("should give collateral balance of user", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log(tx/BigInt(1e18));
    })

    it("should tell if user need liquidation", async function() {
      tx = await collateralPool.needLiquidation(addr1.address);
      console.log(tx);
    })

  });

});
