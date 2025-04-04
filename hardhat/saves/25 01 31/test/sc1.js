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

  let rewardsClaimed;
  let feesClaimed;

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

      await fakeUSDC.transfer(addr2.address, BigInt(10000000e18));
      await fakeWBTC.transfer(addr2.address, BigInt(10000e18));
  
    })


    it("Should deploy Fakeoracles", async function() {
    
      FakeOracle = await ethers.getContractFactory("fakeOracle");
      fakeEthOracle = await FakeOracle.deploy();
      fakeBtcOracle = await FakeOracle.deploy();

      await fakeEthOracle.setPrice(BigInt(2200e8));
      await fakeBtcOracle.setPrice(BigInt(52800e8));
    
    })
    
    it("Should create contracts", async function() {

      Main = await ethers.getContractFactory("Main");
      main = await Main.deploy(fakeUSDC.target);
  
      CollateralPool = await ethers.getContractFactory("CollateralPool");
      collateralPool = await CollateralPool.deploy(fakeUSDC, main.target);
      
      Dashboard = await ethers.getContractFactory("Dashboard");
      dashboard = await Dashboard.deploy(main.target);
  
    })

    it("Should initialize Main", async function() {

      await main.setCollateralPool(collateralPool.target);
  
    })
      
    it("Should create the market WBTC/USDC", async function() {
  
      MarketPool = await ethers.getContractFactory("MarketPool");
      marketPool = await MarketPool.deploy(main.target, fakeWBTC, fakeUSDC, fakeBtcOracle.target, 8, BigInt(500e18), BigInt(20e16));
  
    })

    it("Should link market to Main", async function() {
  
      await main.linkMarket(marketPool.target);
  
    })

    it("Should do all approvals", async function() {
  
      await fakeUSDC.approve(collateralPool.target, BigInt(1000000000e18));
      await fakeUSDC.approve(marketPool.target, BigInt(1000000000e18));
      await fakeWBTC.approve(marketPool.target, BigInt(1000000000e18));

      await fakeUSDC.connect(addr1).approve(collateralPool.target, BigInt(1000000000e18));
      await fakeUSDC.connect(addr1).approve(marketPool.target, BigInt(1000000000e18));
      await fakeWBTC.connect(addr1).approve(marketPool.target, BigInt(1000000000e18));

      await fakeUSDC.connect(addr2).approve(collateralPool.target, BigInt(1000000000e18));
      await fakeUSDC.connect(addr2).approve(marketPool.target, BigInt(1000000000e18));
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

    it("Should deposit call LP at correct interval for Owner", async function() {
      let strikeValue = BigInt("53500000000000000000000");
      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log(tx);

      tx = await marketPool.deposit(true, BigInt(4e18));

      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log(tx);
    })

    it("Should deposit call LP at correct interval for addr2", async function() {
      let strikeValue = BigInt("53500000000000000000000");
      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log(tx);

      tx = await marketPool.connect(addr2).deposit(true, BigInt(3e18));

      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log(tx);
    })

  })

  describe("Trades :: Check", function() {

    it("Should deposit collateral for addr1", async function() {
      tx = await collateralPool.getUserInfos(addr1.address);
      console.log(tx);
      
      await collateralPool.connect(addr1).depositCollateral(BigInt(1500e18));

      tx = await collateralPool.getUserInfos(addr1.address);
      console.log(tx);
    })

    it("Should open a trade for addr1", async function() {
      let strikeValue = BigInt("53500000000000000000000");
      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log("StrikeInfos Before : "+tx);


      await marketPool.connect(addr1).openContract(true, BigInt(5e18));

      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log("StrikekInfos After : "+tx);
      tx = await collateralPool.getUserInfos(addr1.address);
      console.log("UserInfos After : "+tx);
    })

  })

  describe("Time :: Change", function() {

    it("should change block and timestamp", async function() {
      await mine(259200);
      console.log("...3 days")
    })

  });

  describe("LPs :: Check 11111111111111", function() {

    it("Should give user rewards", async function() {
      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Trades :: Check Dashboard", function() {

    it("Should give market's total OI", async function() {
      tx = await dashboard.getMarketOpenInterest(0);
      console.log(tx);
    })

    it("Should give market's total Liquidity Provided", async function() {
      tx = await dashboard.getMarketLiquidityProvided(0);
      console.log(tx);
    })

    it("Should give market's available liquidation", async function() {
      tx = await dashboard.getMarketAvailableLiquidation(0);
      console.log(tx);
    })

  })

  describe("Trades :: Check", function() {

    it("Should give addr1 fees", async function() {
      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

    it("Should give addr1 balance", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log("Trader balance USDC : "+tx/BigInt(1e18));
    })

    it("Should say if need to liquidiate addr1", async function() {
      tx = await collateralPool.needLiquidation(addr1.address);
      console.log("Trader need liquidation : "+tx);
    })

    it("Should deposit collateral for addr1", async function() {
      tx = await collateralPool.getUserInfos(addr1.address);
      console.log(tx);
      
      await collateralPool.connect(addr1).depositCollateral(BigInt(1000e18));

      tx = await collateralPool.getUserInfos(addr1.address);
      console.log(tx);
    })

    it("Should give addr1 fees", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log("Trader balance USDC : "+tx/BigInt(1e18));
    })

  })

  describe("LPs :: Check 888888888888", function() {

    it("Should give user rewards", async function() {
      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("LPs :: Check", function() {

    it("Should claim fees for addr1", async function() {
      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));

      let balanceAV = await fakeUSDC.balanceOf(addr2.address);
      await collateralPool.connect(addr2).claimRewards(0, 1);
      let balanceAP = await fakeUSDC.balanceOf(addr2.address);
      console.log(balanceAP - balanceAV);
      
      rewardsClaimed = BigInt(tx);
    
    })

  })

  describe("LPs :: Check 99999999999", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Trades :: Check", function() {

    it("Should open a trade for addr1", async function() {
      let strikeValue = BigInt("53500000000000000000000");
      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log("StrikeInfos Before : "+tx);

      tx = await collateralPool.getUserFees(addr1.address);
      feesClaimed = tx;

      await marketPool.connect(addr1).openContract(true, BigInt(2e18));     

      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log("StrikekInfos After : "+tx);
      tx = await collateralPool.getUserInfos(addr1.address);
      console.log("UserInfos After : "+tx);
    })

  })

  describe("LPs :: Check xxxxxxxxxxxxxxxxxx", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Time :: Change", function() {

    it("should change block and timestamp", async function() {
      await mine(259200);
      console.log("...3 days")
    })

  });

  describe("Trades :: Check yyyyyyyyyyyyyy", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("LPs :: Check", function() {

    it("Should claim fees for owner", async function() {
      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx);
      rewardsClaimed += tx;

      let balanceAV = await fakeUSDC.balanceOf(owner.address);
      await collateralPool.claimRewards(0, 0);
      let balanceAP = await fakeUSDC.balanceOf(owner.address);
      console.log(balanceAP - balanceAV);

    })

    it("Should claim fees for addr2", async function() {
      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx);
      rewardsClaimed += tx;

      let balanceAV = await fakeUSDC.balanceOf(addr2.address);
      await collateralPool.connect(addr2).claimRewards(0, 1);
      let balanceAP = await fakeUSDC.balanceOf(addr2.address);
      console.log(balanceAP - balanceAV);

    })

  })

  describe("Trades :: Check zzzzzzzzzzzz", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Time :: Change", function() {

    it("should change block and timestamp", async function() {
      await mine(86400);
      console.log("...1 days")
    })

  });

  describe("Trades :: Check", function() {

    it("Should give addr1 fees", async function() {
      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

    it("Should give addr1 balance", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log("Trader balance USDC : "+tx/BigInt(1e18));
    })

    it("Should say if need to liquidiate addr1", async function() {
      tx = await collateralPool.needLiquidation(addr1.address);
      console.log("Trader need liquidation : "+tx);
    })

    it("Should deposit collateral for addr1", async function() {
      tx = await collateralPool.getUserInfos(addr1.address);
      console.log(tx);
      
      await collateralPool.connect(addr1).depositCollateral(BigInt(1000e18));

      tx = await collateralPool.getUserInfos(addr1.address);
      console.log(tx);
    })

    it("Should give addr1 fees", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log("Trader balance USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Trades :: Check zzzzzzzzzzzz", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Oracles :: Prices moove", function() {

    it("should moove the prices", async function() {
      await fakeBtcOracle.setPrice(BigInt(58200e8));
      tx = await marketPool.getPrice();
      console.log("Current price : "+tx/BigInt(1e18));
    })

  });

  describe("LPs :: Check", function() {

    it("Should claim fees for owner", async function() {
      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx);
      rewardsClaimed += tx;

      let balanceAV = await fakeUSDC.balanceOf(owner.address);
      await collateralPool.claimRewards(0, 0);
      let balanceAP = await fakeUSDC.balanceOf(owner.address);
      console.log(balanceAP - balanceAV);

    })

    it("Should claim fees for addr2", async function() {
      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx);
      rewardsClaimed += tx;

      let balanceAV = await fakeUSDC.balanceOf(addr2.address);
      await collateralPool.connect(addr2).claimRewards(0, 1);
      let balanceAP = await fakeUSDC.balanceOf(addr2.address);
      console.log(balanceAP - balanceAV);

    })

  })

  describe("Trades :: Check aaaaaaaaaaaaa", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Trades :: Check", function() {

    it("Should exercise contract 1", async function() {
      let balanceBTCAV = await fakeWBTC.balanceOf(addr1.address);
      let balanceUSDCAV = await fakeUSDC.balanceOf(addr1.address);

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Fees claimed : "+tx/BigInt(1e18));
      feesClaimed += tx;

      await marketPool.connect(addr1).closeContract(0);
      let balanceBTCAP = await fakeWBTC.balanceOf(addr1.address);
      let balanceUSDCAP = await fakeUSDC.balanceOf(addr1.address);
      console.log("Balance WBTC change: "+(balanceBTCAP - balanceBTCAV)/BigInt(1e18));
      console.log("Balance USDC change: "+(balanceUSDCAP - balanceUSDCAV)/BigInt(1e18));
    })


  })

  describe("Trades :: Check bbbbbbbbbbbbbb", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Trades :: Check cccccccccccccc", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Time :: Change", function() {

    it("should change block and timestamp", async function() {
      await mine(86400);
      console.log("...1 days")
    })

  });

  describe("Trades :: Check", function() {

    it("Should give addr1 fees", async function() {
      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

    it("Should give addr1 balance", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log("Trader balance USDC : "+tx/BigInt(1e18));
    })

    it("Should say if need to liquidiate addr1", async function() {
      tx = await collateralPool.needLiquidation(addr1.address);
      console.log("Trader need liquidation : "+tx);
    })

    it("Should deposit collateral for addr1", async function() {
      tx = await collateralPool.getUserInfos(addr1.address);
      console.log(tx);
      
      await collateralPool.connect(addr1).depositCollateral(BigInt(3000e18));

      tx = await collateralPool.getUserInfos(addr1.address);
      console.log(tx);
    })

    it("Should give addr1 balance", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log("Trader balance USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Trades :: Check ddddddddddddddddd", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Trades :: Check Dashboard", function() {

    it("Should give market's total OI", async function() {
      tx = await dashboard.getMarketOpenInterest(0);
      console.log(tx);
    })

    it("Should give market's total Liquidity Provided", async function() {
      tx = await dashboard.getMarketLiquidityProvided(0);
      console.log(tx);
    })

    it("Should give market's available liquidation", async function() {
      tx = await dashboard.getMarketAvailableLiquidation(0);
      console.log(tx);
    })

    it("Should give market's owner LP infos", async function() {
      tx = await dashboard.getUserLpInfosForMarket(0, owner.address);
      console.log(tx);
    })

    it("Should give market's addr2 LP infos", async function() {
      tx = await dashboard.getUserLpInfosForMarket(0, addr2.address);
      console.log(tx);
    })

  })

  describe("LPs :: Check", function() {

    it("Should withdraw call LP for Owner", async function() {

      let strikeValue = BigInt("53500000000000000000000");
      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log(tx);
      tx = await marketPool.withdraw(0);
      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log(tx);

      rewardsClaimed += BigInt(33e18);

    })

  })

  describe("Trades :: Check eeeeeeeeeeeeeeeeee", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for owner : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })


  describe("Time :: Change", function() {

    it("should change block and timestamp", async function() {
      await mine(172800);
      console.log("...2 days")
    })

  });

  describe("Trades :: Check ffffffffffffffffffffff", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      console.log("rewards for owner : 0");

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Trades :: Check", function() {

    it("Should give addr1 fees", async function() {
      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

    it("Should give addr1 balance", async function() {
      tx = await collateralPool.balanceOf(addr1.address);
      console.log("Trader balance USDC : "+tx/BigInt(1e18));
    })

    it("Should say if need to liquidiate addr1", async function() {
      tx = await collateralPool.needLiquidation(addr1.address);
      console.log("Trader need liquidation : "+tx);
    })

  })

  describe("LPs :: Check", function() {

    it("Should claim fees for addr1", async function() {
      tx = await collateralPool.getRewardsForLp(0, 0);
      console.log("rewards for addr1 : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));

      let balanceAV = await fakeUSDC.balanceOf(addr2.address);
      await collateralPool.connect(addr2).claimRewards(0, 1);
      let balanceAP = await fakeUSDC.balanceOf(addr2.address);
      console.log(balanceAP - balanceAV);
      
      rewardsClaimed += BigInt(tx);
    
    })

  })

  describe("Trades :: Check ggggggggggggggggggggg", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      
      console.log("rewards for owner : 0");

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("LPs :: Check", function() {

    it("Should deposit call LP at correct interval for Owner", async function() {
      let strikeValue = BigInt("57500000000000000000000");
      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log(tx);

      let amountValue = BigInt("172500000000000000000000");
      tx = await marketPool.deposit(false, amountValue);

      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log(tx);
    })

    
    it("Should deposit call LP at correct interval for addr2", async function() {
      let strikeValue = BigInt("57500000000000000000000");
      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log(tx);

      let amountValue = BigInt("57500000000000000000000");
      tx = await marketPool.connect(addr2).deposit(false, amountValue);

      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log(tx);
    })

  })

  describe("Trades :: Check", function() {

    it("Should open a trade for addr1", async function() {
      let strikeValue = BigInt("57500000000000000000000");
      let amountValue = BigInt("115000000000000000000000");

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Fees claimed : "+tx/BigInt(1e18));
      feesClaimed += tx;

      await marketPool.connect(addr1).openContract(false, amountValue);

      tx = await marketPool.getStrikeInfos(strikeValue);
      console.log("StrikekInfos After : "+tx);
      tx = await collateralPool.getUserInfos(addr1.address);
      console.log("UserInfos After : "+tx);
    })

  })

  describe("Trades :: Check hhhhhhhhhhhhhhhhhhhhhh", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 2);
      console.log("rewards for owner put : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 call : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 3);
      console.log("rewards for addr2 put : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Time :: Change", function() {

    it("should change block and timestamp", async function() {
      await mine(259200);
      console.log("...3 days")
    })

  });

  describe("Trades :: Check Dashboard", function() {

    it("Should give market's total OI", async function() {
      tx = await dashboard.getMarketOpenInterest(0);
      console.log(tx);
    })

    it("Should give market's total Liquidity Provided", async function() {
      tx = await dashboard.getMarketLiquidityProvided(0);
      console.log(tx);
    })

    it("Should give market's available liquidation", async function() {
      tx = await dashboard.getMarketAvailableLiquidation(0);
      console.log(tx);
    })

  })

  describe("Oracles :: Prices moove", function() {

    it("should moove the prices", async function() {
      await fakeBtcOracle.setPrice(BigInt(55900e8));
      tx = await marketPool.getPrice();
      console.log("Current price : "+tx/BigInt(1e18));
    })

  });

  describe("Trades :: Check iiiiiiiiiiiiiiiiiiiiiiiiiii", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 2);
      console.log("rewards for owner put : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 call : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 3);
      console.log("rewards for addr2 put : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Trades :: Check", function() {

    it("Should exercise contract 2", async function() {
      let balanceBTCAV = await fakeWBTC.balanceOf(addr1.address);
      let balanceUSDCAV = await fakeUSDC.balanceOf(addr1.address);

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Fees claimed : "+tx/BigInt(1e18));
      feesClaimed += tx;

      await marketPool.connect(addr1).closeContract(2);
      let balanceBTCAP = await fakeWBTC.balanceOf(addr1.address);
      let balanceUSDCAP = await fakeUSDC.balanceOf(addr1.address);
      console.log("Balance WBTC change: "+(balanceBTCAP - balanceBTCAV)/BigInt(1e18));
      console.log("Balance USDC change: "+(balanceUSDCAP - balanceUSDCAV)/BigInt(1e18));
    })

  })

  describe("LPs :: Check", function() {

    it("Should claim fees for addr1", async function() {
      tx = await collateralPool.getRewardsForLp(0, 2);
      console.log("rewards for owner put : "+tx/BigInt(1e18));

      rewardsClaimed += BigInt(tx);

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 call : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 3);
      console.log("rewards for addr2 put : "+tx/BigInt(1e18));

      rewardsClaimed += BigInt(tx);

      let balanceAV = await fakeUSDC.balanceOf(owner.address);
      await collateralPool.claimRewards(0, 2);
      let balanceAP = await fakeUSDC.balanceOf(owner.address);
      console.log(balanceAP - balanceAV);

      balanceAV = await fakeUSDC.balanceOf(addr2.address);
      await collateralPool.connect(addr2).claimRewards(0, 3);
      balanceAP = await fakeUSDC.balanceOf(addr2.address);
      console.log(balanceAP - balanceAV);
    
    })

  })

  describe("Trades :: Check jjjjjjjjjjjjjjjjjjjjjj", function() {

    it("Should give user rewards", async function() {
      console.log("Total Rewards Claimed : "+rewardsClaimed/BigInt(1e18))

      tx = await collateralPool.getRewardsForLp(0, 2);
      console.log("rewards for owner put : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 1);
      console.log("rewards for addr2 call : "+tx/BigInt(1e18));

      tx = await collateralPool.getRewardsForLp(0, 3);
      console.log("rewards for addr2 put : "+tx/BigInt(1e18));
    })

    it("Should give addr1 fees", async function() {
      console.log("Total Fees Claimed : "+feesClaimed/BigInt(1e18))

      tx = await collateralPool.getUserFees(addr1.address);
      console.log("Trader fees USDC : "+tx/BigInt(1e18));
    })

  })

  describe("Trades :: Check Dashboard", function() {

    it("Should give market's total OI", async function() {
      tx = await dashboard.getMarketOpenInterest(0);
      console.log(tx);
    })

    it("Should give market's total Liquidity Provided", async function() {
      tx = await dashboard.getMarketLiquidityProvided(0);
      console.log(tx);
    })

    it("Should give market's available liquidation", async function() {
      tx = await dashboard.getMarketAvailableLiquidation(0);
      console.log(tx);
    })

    it("Should give market's owner LP infos", async function() {
      tx = await dashboard.getUserLpInfosForMarket(0, owner.address);
      console.log(tx);
    })

    it("Should give market's addr2 LP infos", async function() {
      tx = await dashboard.getUserLpInfosForMarket(0, addr2.address);
      console.log(tx);
    })

    it("Should give market's balance detail", async function() {
      tx = await dashboard.getMarketBalanceDetail(0);
      console.log(tx);
    })

  })

});
