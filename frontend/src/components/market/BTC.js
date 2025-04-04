import React, { useState, useEffect } from "react";
import Select from "react-select";
import InfoPopUp from "../InfoPopUp";
import { getStrikesAndLiquidity, getMarketPoolcbBTC, getBtcPrice } from "../../utils/web3";
import { parseUnits } from "ethers";
import { useAccount } from 'wagmi';


export default function BTC() {
    const { isConnected } = useAccount();
    const [isCall, setIsCall] = useState(true);
    const [amount, setAmount] = useState(null);
    const [strikePrices, setStrikePrices] = useState([]);
    const [selectedStrikeIndex, setSelectedStrikeIndex] = useState(0);
    const [maxAmounts, setMaxAmounts] = useState([]);
    const [selectedMaxAmount, setSelectedMaxAmount] = useState(0);
    const [bitcoinPrice, setBitcoinPrice] = useState(null);
    const [popupMessage, setPopupMessage] = useState(null);
    const [infoMessage, setInfoMessage] = useState(null);
    const [txHash, setTxHash] = useState(null);

    useEffect(() => {
        const fetchData = async () => {            
            const data = await getStrikesAndLiquidity(isCall);
            if (data) {
                setStrikePrices(data.strikePrices.map((price, index) => ({
                    index: index,
                    value: price,
                    label: `$${price.toLocaleString()} / BTC`
                })));
                setMaxAmounts(data.availableLiquidity);
            }
        };
        fetchData();
    }, [isCall, selectedStrikeIndex]);

    useEffect(() => {
        fetchBitcoinPrice();
    }, []);

    const fetchBitcoinPrice = async () => {
        try {
            const price = await getBtcPrice();
            setBitcoinPrice(price.toLocaleString());
        } catch (error) {
            console.error("Error fetching Bitcoin price:", error);
            setBitcoinPrice("Error");
        }
    };

    const handleClosePopup = () => {
        setPopupMessage(null);
        setTxHash(null);
        fetchBitcoinPrice();
    };

    const handleToggle = () => {
        setIsCall(!isCall);
        fetchBitcoinPrice();
    };

    const handleStrikeChange = (e) => {
        const index = parseInt(e.index, 10);
        setSelectedStrikeIndex(index);
        setSelectedMaxAmount(index);
        fetchBitcoinPrice();
    };

    const handleSliderChange = (e) => {
        setAmount(e.target.value);
    };

    const openPosition = async () => {
        try {
            const contract = await getMarketPoolcbBTC();
            if (!contract) {
                setPopupMessage("Failed to load contract");
                return;
            }

            setPopupMessage("Creating transaction...");

            const chosenStrike = strikePrices[selectedStrikeIndex]?.value;
            const intervals = await contract.getIntervals();
            let correctIndex;

            // Convert amount to uint256 with 8 decimals
            let contractAmount;
            let formattedAmount;
            if (isCall) {
                contractAmount = amount;
                formattedAmount = parseUnits(contractAmount.toString(), 8);


                // Get Index for this strike
                for (let i = intervals.length/2 ; i < intervals.length ; i++) {
                    if (intervals[i] === parseUnits(chosenStrike.toString(), 18)) {
                        correctIndex = i - intervals.length/2;
                    }
                }

            } else {
                contractAmount = amount * chosenStrike;
                formattedAmount = parseUnits(contractAmount.toString(), 6);

                // Get Index for this strike
                for (let i = 0 ; i < intervals.length/2 ; i++) {
                    if (intervals[i] === parseUnits(chosenStrike.toString(), 18)) {
                        correctIndex = i;
                    }
                }
            }

            const tx = await contract.openContract(isCall, correctIndex, formattedAmount);
            setPopupMessage("loader");
            setTxHash(tx.hash);
            await tx.wait();

            setPopupMessage("Position opened successfully!");
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

            {/* Main Trade Container */}
            <div className="trade-page">
                <div className="trade-container">
                    <div className="tooltip-icon"
                        onMouseEnter={() => setInfoMessage(
                            `<strong>Postpone the Buy or Sell of an asset at your chosen price and amount.</strong><br/>
                            You'll pay a recurring rent based on the size of the contract.<br/><br/>
                            <strong>Call:</strong> Postpone a buy<br/>
                            <strong>Put:</strong> Postpone a sell<br/>
                            <strong>Strike Price:</strong> Target price for the asset<br/>
                            <strong>Amount:</strong> Desired quantity<br/>
                            <strong>Cost:</strong> Rent paid to keep the contract active`
                        )
                    } onMouseLeave={() => setInfoMessage(null)}>
                        ?
                    </div>
                    <div className="action-header">
                        <h1 className="action-title">Option Type</h1>
                        <div className="toggle-switch" onClick={handleToggle}>
                            <div className={`switch ${isCall ? "call" : "put"}`}>
                                {isCall ? "Call" : "Put"}
                            </div>
                        </div>
                    </div>

                    {strikePrices[0] === undefined ? <div className="loaderPositions"></div>
                    : <div className="lock-info">
                        <p className="lock-price">Strike Price</p>
                        <Select
                            options={strikePrices}
                            value={strikePrices.find(option => option.index === selectedStrikeIndex)}
                            onChange={handleStrikeChange}
                            styles={{
                                control: (base) => ({
                                    ...base,
                                    margin: "0 18%",
                                    padding: "2px 0",
                                    border: "2px solid #084e94",
                                    borderRadius: "8px",
                                    boxShadow: "0px 4px 10px rgba(0, 0, 0, 0.1)",
                                    cursor: "pointer",
                                    fontSize: "20px",
                                    fontWeight: "bold",
                                }),
                                menu: (base) => ({
                                    ...base,
                                    borderRadius: "8px",
                                    boxShadow: "0px 4px 10px rgba(0, 0, 0, 0.1)",
                                }),
                                option: (base, state) => ({
                                    ...base,
                                    backgroundColor: state.isFocused ? "#2c3e50" : "#ffffff",
                                    color: state.isFocused ? "#ffffff" : "#333333",
                                    fontWeight: state.isFocused ? "bold" : "normal",
                                    padding: "10px",
                                    borderRadius: "6px",
                                    transition: "background-color 0.3s ease, color 0.3s ease",
                                    boxShadow: state.isFocused ? "0px 4px 10px rgba(0, 0, 0, 0.2)" : "none",
                                    cursor: "pointer",
                                    "&:hover": {
                                        backgroundColor: "#34495e",
                                        color: "#ffffff",
                                    },
                                }),
                                
                            }}
                        />                
                    </div>}
                    
                    <div className="amount-info">
                        {maxAmounts[selectedMaxAmount] === 0 ? (
                            <p>No liquidity at this strike price</p>
                        ) : (
                            isCall ? (
                                <>
                                    <span>Amount</span>
                                    <input
                                        type="range"
                                        min="0"
                                        max={maxAmounts[selectedMaxAmount]}
                                        step="0.00001"
                                        value={amount || 0}
                                        onChange={handleSliderChange}
                                    />
                                    <span className="amount-display">
                                        <input
                                            type="number"
                                            min="0"
                                            max={maxAmounts[selectedMaxAmount]}
                                            step="0.00001"
                                            value={amount || 0}
                                            onChange={(e) => {
                                                let value = parseFloat(e.target.value);
                                                if (isNaN(value)) value = 0;
                                                if (value > parseFloat(maxAmounts[selectedMaxAmount])) value = parseFloat(maxAmounts[selectedMaxAmount]);
                                                setAmount(value);
                                            }}
                                            className="amount-input"
                                        />
                                        BTC
                                    </span>
                                </>
                            ) : (
                                <>
                                    <span>Amount</span>
                                    <input
                                        type="range"
                                        min="0"
                                        max={maxAmounts[selectedMaxAmount]/strikePrices[selectedStrikeIndex]?.value}
                                        step="0.000001"
                                        value={amount || 0}
                                        onChange={handleSliderChange}
                                    />
                                    <span className="amount-display">
                                        <input
                                            type="number"
                                            min="0"
                                            max={maxAmounts[selectedMaxAmount]/strikePrices[selectedStrikeIndex]?.value}
                                            step="0.00001"
                                            value={amount || 0}
                                            onChange={(e) => {
                                                let value = parseFloat(e.target.value);
                                                if (isNaN(value)) value = 0;
                                                if (value > parseFloat(maxAmounts[selectedMaxAmount]/strikePrices[selectedStrikeIndex]?.value)) 
                                                    value = parseFloat(maxAmounts[selectedMaxAmount]/strikePrices[selectedStrikeIndex]?.value);
                                                setAmount(value);
                                            }}
                                            className="amount-input"
                                        />
                                        BTC
                                    </span>
                                </>
                            )
                        )}
                    </div>

                    <div className="rent-info">
                        {strikePrices[0] === undefined
                            ? <div className="loaderPositions"></div>
                            : <p>Cost: ${(((amount * strikePrices[selectedStrikeIndex]?.value) * 0.2) / 52.14).toFixed(2)}/Week</p>
                        }
                    </div>

                    <button className="lock-button" onClick={isConnected ? openPosition : () => setPopupMessage("Please connect your Web3 wallet")}>Open Position</button>
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
