import React, { useState, useEffect } from "react";
import InfoPopUp from "../InfoPopUp";
import { getStrike, getMarketPoolcbBTC, getAllowance, approveTokens, getBtcPrice, getAutoReplacer, approveERC721, getERC721Allowance } from "../../utils/web3";
import { parseUnits } from "ethers";
import { useAccount } from 'wagmi';

/* global BigInt */

export default function BTC_USDC() {
    const { isConnected } = useAccount();
    const [isCall, setIsCall] = useState(true);
    const [isAutoReplace, setIsAutoReplace] = useState(false);
    const [amount, setAmount] = useState(null);
    const [strikePrice, setStrikePrice] = useState(null);
    const [bitcoinPrice, setBitcoinPrice] = useState(null);
    const [popupMessage, setPopupMessage] = useState(null);
    const [infoMessage, setInfoMessage] = useState(null);
    const [txHash, setTxHash] = useState(null);

    useEffect(() => {
        const fetchData = async () => {
            const data = await getStrike(isCall);
            if (data) {
                setStrikePrice(data.strikePrice);
            }
        };
        fetchData();
    }, [isCall]);

    useEffect(() => {
        const fetchBitcoinPrice = async () => {
            try {
                const price = await getBtcPrice();
                setBitcoinPrice(price.toLocaleString());
            } catch (error) {
                console.error("Error fetching Bitcoin price:", error);
                setBitcoinPrice("Error");
            }
        };

        fetchBitcoinPrice();
    }, []);

    const handleClosePopup = () => {
        setPopupMessage(null);
        setTxHash(null);
    };

    const handleToggle = () => {
        setIsCall(!isCall);
    };

    const handleAutoReplaceToggle = () => {
        setIsAutoReplace(!isAutoReplace);
    };

    const startAutoReplace = async (id) => {
        try {
            const contract = await getAutoReplacer();
            if (contract) {

                // Market Pool
                const marketPool = await getMarketPoolcbBTC();
                const ERC721_LP = await marketPool.getERC721_LP();

                // Check allowance
                const allowedTo = await getERC721Allowance(ERC721_LP, id);

                if (allowedTo !== contract.target) {
                    // Approve
                    setPopupMessage("Approving token for Auto Replace...");
                    await approveERC721(ERC721_LP, contract.target, id);
                    setPopupMessage("Confirming transaction...");
                }

                const tx = await contract.startAutoReplace(0, id);
                setPopupMessage("loader");
                setTxHash(tx.hash);
                await tx.wait();
                setPopupMessage("Auto Replace successfully started.");
            }
        } catch (error) {
            console.error("Auto Replace failed.", error);
            setPopupMessage("Transaction failed.");
        }
    };

    const depositLiquidity = async () => {
        try {
            const contract = await getMarketPoolcbBTC();
            if (!contract) {
                setPopupMessage("Failed to load contract");
                return;
            }

            // Convert amount to uint256 with 8 decimals
            let formattedAmount;
            isCall ? formattedAmount = parseUnits(amount.toString(), 8) : formattedAmount = parseUnits(amount.toString(), 6);

            // Allowance check
            const tokenAddress = isCall ? await contract.getTokenA() : await contract.getTokenB();
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

            const tx = await contract.deposit(isCall, formattedAmount);
            setPopupMessage("loader");
            setTxHash(tx.hash);

            const receipt = await tx.wait();

            // Extract lpId from the Deposit event
            let id;
            for (const event of receipt.logs) {
                try {
                    const parsed = contract.interface.parseLog(event);
                    if (parsed.name === "Deposit") {
                        id = parsed.args.lpId.toString();
                        break;
                    }
                } catch (e) {
                    // Ignore logs that don’t belong to this contract
                }
            }

            // If user want to Autoreplace
            if (isAutoReplace && id) {
                startAutoReplace(id);
            } else {
                setPopupMessage("Position opened successfully!");
            }

        } catch (error) {
            console.error("Transaction failed.", error);
            setPopupMessage("Transaction failed.");
        }
    };

    return (
        <div>
            {/* Bitcoin Live Price Section */}
           <div className="bitcoin-live">
                <span className="live-dot"></span>
                <h2>Bitcoin</h2>
                <p className="bitcoin-price">{bitcoinPrice === null ? <div className="loaderInfos"></div> : `$${bitcoinPrice}`}</p>
            </div>

            {/* Earn Container */}
            <div className="earn-page">
                <div className="earn-container">
                    <div className="tooltip-icon"
                        onMouseEnter={() => setInfoMessage(
                            `<strong>Deposit Liquidity</strong> into the protocol for traders to open Perpetual Option Contracts. Used liquidity can’t be withdrawn.<br/><br/>
                            <strong>Call:</strong> Deposit WBTC → converted to USDC at strike price<br/>
                            <strong>Put:</strong> Deposit USDC → converted to WBTC at strike price<br/>
                            <strong>Strike Price:</strong> The exchange price<br/>
                            <strong>Auto Replace:</strong> Auto-move unused liquidity to the closest strike price`
                        )
                    } onMouseLeave={() => setInfoMessage(null)}>
                        ?
                    </div>
                    <div className="action-header">
                        <h1 className="action-title">Deposit</h1>
                        <div className="toggle-switch" onClick={handleToggle}>
                            <div className={`switch ${isCall ? "call" : "put"}`}>
                                {isCall ? "Call" : "Put"}
                            </div>
                        </div>
                        <img 
                            src={isCall ? "/logo-btc.png" : "/logo-usdc.png"} 
                            alt={isCall} 
                            className="currency-logo"
                        />
                    </div>

                    <div className="lock-info">
                        <p className="lock-price">Strike Price</p>
                        <p className="lock-strikePrice">{strikePrice === null ? <div className="loaderPositions"></div> : `$${strikePrice.toLocaleString()} / BTC`}</p>
                    </div>

                    <div className="amount-info">
                        <input
                            type="number"
                            placeholder={`0.00 ${isCall ? "BTC" : "USDC"}`}
                            value={amount}
                            onChange={(e) => setAmount(e.target.value)}
                            className="amount-input"
                        />
                    </div>

                    <div className="rent-info">
                        {strikePrice === null ? <div className="loaderPositions"></div> : (
                            isCall ? (
                                <p>Earnings: ${(((amount * strikePrice) * 0.2) / 52.14).toFixed(2)}/Week</p>
                            ) : (
                                <p>Earnings: ${((amount * 0.2) / 52.14).toFixed(2)}/Week</p>
                            )
                        )}
                    </div>

                    <div className="autoReplace-toggle" onClick={handleAutoReplaceToggle}>
                        Auto Replace:&nbsp;
                        <div className="toggle-autoSwitch" >
                            <div className={`autoSwitch ${isAutoReplace ? "on" : "off"}`}>
                                <img 
                                    src={isAutoReplace ? "/eclair.png" : "/no-eclair.png"} 
                                    alt="autoRepalce Status" 
                                />
                            </div>
                        </div>
                        
                    </div>

                    <button className="deposit-button" onClick={isConnected ? depositLiquidity : () => setPopupMessage("Please connect your Web3 wallet")}>Deposit</button>
                </div>
            </div>
            {popupMessage && <InfoPopUp message={popupMessage} txHash={txHash} onClose={handleClosePopup} />}
            {infoMessage === null ? null : (
                <div
                    className="info-message"
                    dangerouslySetInnerHTML={{ __html: infoMessage }}
                />
            )}
            {!isConnected ? (
                <div className="bottom-message">Please connect your Web3 wallet</div>
            ) : null}
        </div>
    );
}
