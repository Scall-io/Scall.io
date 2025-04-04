import React, { useState, useEffect } from "react";
import InfoPopUp from "./InfoPopUp";
import { getCollateralPool, getUserInfos, getMarketPoolcbBTC, getAutoReplacer, getUserHelper, getAllowance, getERC721Allowance, approveTokens, approveERC721, getERC721 } from "../utils/web3";
import { ethers } from "ethers";

/* global BigInt */

export default function Dashboard() {
    const [amount, setAmount] = useState("");
    const [openTrades, setOpenTrades] = useState(null);
    const [liquidityPositions, setLiquidityPositions] = useState(null);
    const [totalRewards, setTotalRewards] = useState(null);
    const [totalOI, setTotalOI] = useState(null);
    const [expectedEarnings, setExpectedEarnings] = useState(null);
    const [weeklyCost, setWeeklyCost] = useState(null);
    const [remainingCollateral, setRemainingCollateral] = useState(null);
    const [withdrawableCollateral, setWithdrawableCollateral] = useState(null);
    const [popupMessage, setPopupMessage] = useState(null);
    const [txHash, setTxHash] = useState(null);

    useEffect(() => {
        fetchUserData();
    }, []);

    const fetchUserData = async () => {
        const userInfo = await getUserInfos();
        if (userInfo) {
            const rent = parseFloat(userInfo.rent);
            const balance = parseFloat(userInfo.balance);
            const weeklyRentCost = rent * 604800;
            const totalRewards = parseFloat(userInfo.lpTotalRewards);
            const totalOI = parseFloat(userInfo.lpTotalOI);

            setOpenTrades(userInfo.contractPositions);
            setLiquidityPositions(userInfo.liquidityPositions);
            setWeeklyCost(weeklyRentCost.toFixed(2));
            setRemainingCollateral((Math.floor(balance * 100) / 100).toFixed(2));
            setWithdrawableCollateral(((Math.floor(balance * 100) / 100) - weeklyRentCost).toFixed(2));
            setTotalRewards(totalRewards.toFixed(2));
            setTotalOI(totalOI.toFixed(2));
            setExpectedEarnings(userInfo.lpExpectedEarnings)
        }
    };

    const handleClosePopup = () => {
        setPopupMessage(null);
        setTxHash(null);
    };

    const depositCollateral = async () => {
        try {
            const contract = await getCollateralPool();
            if (contract) {

                let formattedAmount = ethers.parseUnits(amount, 6);

                // Allowance check
                const tokenAddress = await contract.getCollateralToken();
                const spender = contract.target;
    
                const allowance = await getAllowance(tokenAddress, spender);
    
                // Convert allowance and formattedAmount to BigInt for comparison
                const allowanceBigInt = BigInt(allowance.toString());
                const amountBigInt = BigInt(formattedAmount.toString());
    
                if (allowanceBigInt < amountBigInt) {
                    setPopupMessage("Approving tokens...");
                    await approveTokens(tokenAddress, spender, formattedAmount);
                    setPopupMessage("Confirming transaction...");
                }

                const tx = await contract.depositCollateral(formattedAmount);
                setPopupMessage("loader");
                setTxHash(tx.hash);
                await tx.wait();
                setPopupMessage("Deposit Successful!");
            }

            fetchUserData();
        } catch (error) {
            console.error("Transaction failed.", error);
            setPopupMessage("Transaction failed.");
        }
    };

    const withdrawCollateral = async () => {
        try {
            const contract = await getCollateralPool();
            if (contract) {
                const tx = await contract.withdrawCollateral(ethers.parseUnits(amount, 6));
                setPopupMessage("loader");
                setTxHash(tx.hash);
                await tx.wait();
                setPopupMessage("Withdraw Successful!");
            }

            fetchUserData();
        } catch (error) {
            console.error("Transaction failed.", error);
            setPopupMessage("Transaction failed.");
        }
    };

    const claimRewards = async () => {
        try {
            const contract = await getUserHelper();
            if (contract) {
                console.log(contract);
                const tx = await contract.claimAllRewards();
                setPopupMessage("loader");
                setTxHash(tx.hash);
                await tx.wait();
                setPopupMessage("Claim Successful!");
            }

            fetchUserData();
        } catch (error) {
            console.error("Transaction failed.", error);
            setPopupMessage("Transaction failed.");
        }
    };

    const closeContract = async (_id) => {
        try {
            const contract = await getMarketPoolcbBTC();
            if (contract) {
                setPopupMessage("Closing Trade...");

                const userTrade = openTrades.find(trade => parseInt(trade.id) === _id);

                if (userTrade.isITM) {
                    const tokenToApprove = userTrade.type === "Call" ? await contract.getTokenB() : await contract.getTokenA();
                    const spender = contract.target; // MarketPool
                    const amountToApprove = userTrade.type === "Call" 
                        ? userTrade.amount * userTrade.strikePrice 
                        : userTrade.amount / userTrade.strikePrice;
                    
                    const parsedAmountToApprove = userTrade.type === "Call"
                        ? ethers.parseUnits(amountToApprove.toString(), 6)
                        : ethers.parseUnits(amountToApprove.toString(), 8)

                    // Check allowance
                    const allowance = await getAllowance(tokenToApprove, spender);
                    if (BigInt(allowance.toString()) < BigInt(parsedAmountToApprove.toString())) {
                        setPopupMessage("Approving tokens...");
                        await approveTokens(tokenToApprove, spender, parsedAmountToApprove);
                        setPopupMessage("Confirming transaction...");
                    }
                }

                const tx = await contract.closeContract(_id);
                setPopupMessage("loader");
                setTxHash(tx.hash);
                await tx.wait();
                setPopupMessage("Close Successful!");

                fetchUserData();
            }
        } catch (error) {
            console.error("Transaction failed.", error);
            setPopupMessage("Transaction failed.");
        }
    };

    const closeLP = async (_lp) => {
        try {
            const contract = await getMarketPoolcbBTC();
            if (contract) {

                // If AutoReplaced
                if (_lp.isAutoReplaced) {
                    await stopAutoReplace(_lp);
                }
                setPopupMessage("Closing Position...");
                
                const tx = await contract.withdraw(_lp.id);
                setPopupMessage("loader");
                setTxHash(tx.hash);
                await tx.wait();
                setPopupMessage("Close Successful!");

                fetchUserData();
            }
        } catch (error) {
            console.error("Transaction failed.", error);
            setPopupMessage("Transaction failed.");
        }
    };

    const startAutoReplace = async (lp) => {
        try {
            const contract = await getAutoReplacer();
            if (contract) {
                setPopupMessage("Starting Auto Replace...");

                // Market Pool
                const marketPool = await getMarketPoolcbBTC();
                const ERC721_LP = await marketPool.getERC721_LP();

                // Check allowance
                const allowedTo = await getERC721Allowance(ERC721_LP, lp.id);

                if (allowedTo !== contract.target) {
                    // Approve
                    setPopupMessage("Approving token...");
                    await approveERC721(ERC721_LP, contract.target, lp.id);
                    setPopupMessage("Confirming transaction...");
                }

                const tx = await contract.startAutoReplace(lp.index, lp.id);
                setPopupMessage("loader");
                setTxHash(tx.hash);
                await tx.wait();
                setPopupMessage("Auto Replace successfully started.");
                fetchUserData();
            }
        } catch (error) {
            console.error("Auto Replace failed.", error);
            setPopupMessage("Transaction failed.");
        }
    };

    const stopAutoReplace = async (lp) => {
        try {
            const contract = await getAutoReplacer();
            if (contract) {
                setPopupMessage("Stopping Auto Replace...");

                const provider = new ethers.BrowserProvider(window.ethereum);
                const signer = await provider.getSigner();
                const userAddress = await signer.getAddress();

                // Check autoReplace Ids owned by user
                const ERC721_AutoReplaceAddr = await contract.getERC721_AutoReplace();
                const ERC721 = await getERC721(ERC721_AutoReplaceAddr);
                const Balance = await ERC721.balanceOf(userAddress);

                // Among this AutoRepalce Ids, get the one representing lp.id                
                let correctAutoReplaceID;
                for (let i = 0 ; i < Balance ; i++) {
                    let autoReplaceID = await ERC721.tokenOfOwnerByIndex(userAddress, i);
                    let autoReplaceIDInfos = await contract.getAutoReplaceInfos(autoReplaceID);

                    if (Number(autoReplaceIDInfos.id) === lp.id) {
                        correctAutoReplaceID = autoReplaceID;
                    }
                }

                const tx = await contract.stopAutoReplace(correctAutoReplaceID);
                setPopupMessage("loader");
                setTxHash(tx.hash);
                await tx.wait();
                setPopupMessage("Transaction successfull.");
                fetchUserData();
            }
        } catch (error) {
            console.error("Transaction failed.", error);
            setPopupMessage("Transaction failed.");
        }
    };

    return (
        <div className="dashboard-grid">
            <div className="dashboard-card">
                <h2>Collateral Management</h2>
                <p className="info">Collateral: <span onClick={() => setAmount(remainingCollateral)} style={{ cursor: 'pointer' }} title="Click to auto-fill">{remainingCollateral === null ? <div className="loaderInfos"></div> : `${remainingCollateral}`}<img src={"/logo-usdc.png"} alt="user infos"/></span></p>
                <p className="info">Weekly Cost: <span>{weeklyCost === null ? <div className="loaderInfos"></div> : `${weeklyCost}`}<img src={"/logo-usdc.png"} alt="user infos"/></span></p>
                <p className="info">Withdrawable Collateral: <span onClick={() => setAmount(withdrawableCollateral)} style={{ cursor: 'pointer' }} title="Click to auto-fill"> {withdrawableCollateral === null ? <div className="loaderInfos"></div> : `${withdrawableCollateral}`}<img src={"/logo-usdc.png"} alt="user infos"/></span></p>
                <div className="input-group">
                    <input
                        type="number"
                        placeholder="Enter Amount"
                        value={amount}
                        onChange={(e) => setAmount(e.target.value)}
                    />
                </div>
                <div className="button-group">
                    <button className="deposit-collateral-button" onClick={depositCollateral}>Deposit</button>
                    <button className="withdraw-collateral-button" onClick={withdrawCollateral}>Withdraw</button>
                </div>
            </div>

            <div className="dashboard-card">
                <h2>Liquidity Management</h2>
                <p className="info">Open Interest: <span>{totalOI === null ? <div className="loaderInfos"></div> : `${totalOI}`}<img src={"/logo-usdc.png"} alt="user infos"/></span></p>
                <p className="info">Current APR: <span>{expectedEarnings === null ? <div className="loaderInfos"></div> : `${expectedEarnings === "0.0" ? 0 : ((expectedEarnings/totalOI)*100).toFixed(2)} %`}</span></p>
                <p className="info">Total Rewards: <span>{totalRewards === null ? <div className="loaderInfos"></div> : `${totalRewards}`}<img src={"/logo-usdc.png"} alt="user infos"/></span></p>
                <button className="claim-button" onClick={() => claimRewards()}>Claim Rewards</button>
            </div>

            <div className="dashboard-card">
                <h2>Open Trade Positions</h2>
                {openTrades === null ? (
                    <div className="loaderPositions"></div>
                ) : openTrades.length > 0 ? (
                    <ul>
                        {openTrades.map((trade) => (
                            <li key={trade.asset + trade.id}>
                                <div className="tradeInfos">
                                    <span className="basicContractInfos">
                                        <img src={`/logo-${trade.asset.toLowerCase()}.png`} alt="user infos"/>
                                        <span className="gradient-text">
                                            - {trade.type === "Call" ? trade.amount.toFixed(4) : (trade.amount/trade.strikePrice).toFixed(4)} @ ${trade.strikePrice}
                                        </span> 
                                        {trade.type}
                                    </span>
                                    <span className="otherContractInfos">
                                        <span>
                                            <b>Rent:</b> ${(trade.rent*604800).toFixed(2)}/week 
                                            <b> Earnings: <span className="greenColor">${trade.earnings.toFixed(2)}</span></b>
                                        </span>
                                    </span>
                                </div>
                                <button className={trade.earnings > 0 ? "execute-button" : "close-button"} onClick={() => closeContract(trade.id)}>{trade.earnings > 0 ? "Execute" : "Close"}</button>
                            </li>
                        ))}
                    </ul>
                ) : (
                    <p className="info">No open trades</p>
                )}
            </div>

            <div className="dashboard-card">
                <h2>Liquidity Provider Positions</h2>
                {liquidityPositions === null ? (
                    <div className="loaderPositions"></div>
                ) : liquidityPositions.length > 0 ? (
                    <ul>
                        {liquidityPositions.map((lp) => (
                            <li key={lp.asset + lp.id}>
                                <div className="lpInfos">
                                    <span className="basicContractInfos">
                                        <img src={`/logo-${lp.market.toLowerCase()}.png`} alt="user infos"/>
                                        <span className="gradient-text">
                                            - {lp.type === "Call" ? lp.amount.toFixed(4) : lp.amount.toFixed(2)} {lp.asset} @ ${lp.strikePrice}
                                        </span> 
                                        {lp.type}
                                    </span>
                                    <span className="otherContractInfos">
                                        <span>
                                            <b>Value:</b> {lp.type === "Call" ? lp.value.toFixed(4) : lp.value.toFixed(2)} <img src={`/logo-${lp.asset.toLowerCase()}.png`} alt="user infos"/> 
                                            <b>&nbsp;&nbsp; Avl:</b> {lp.withdrawableTokenA.toFixed(4)} <img src={`/logo-${lp.market.toLowerCase()}.png`} alt="user infos"/> & {lp.withdrawableTokenB.toFixed(2)} <img src={`/logo-usdc.png`} alt="user infos"/>
                                        </span>
                                    </span>
                                </div>
                                <button
                                    className={`thunder-button`}
                                    onClick={lp.isAutoReplaced ? () => stopAutoReplace(lp) : () => startAutoReplace(lp)}
                                    title={lp.isAutoReplaced ? "Auto Replace ON" : "Auto Replace OFF"}
                                >
                                    {lp.isAutoReplaced ? (
                                        <img
                                            src="/eclair.png"
                                            alt="Auto Replace Off"
                                        />
                                    ) : (
                                        <img
                                            src="no-eclair.png"
                                            alt="Auto Replace Off"
                                        />
                                    )}
                                </button>
                                <button className="close-button" onClick={() => closeLP(lp)}>Close</button>
                            </li>
                        ))}
                    </ul>
                ) : (
                    <p className="info">No liquidity provider positions</p>
                )}
            </div>
            {popupMessage && <InfoPopUp message={popupMessage} txHash={txHash} onClose={handleClosePopup} />}
            {remainingCollateral === null ? <div className="bottom-message">Please connect your Web3 wallet</div> : ""}
        </div>
    );
}
