import React from "react";

const InfoPopUp = ({ message, txHash, onClose }) => {
    return (
        <div className="info-popup-overlay" onClick={onClose}>
            <div className="info-popup" onClick={(e) => e.stopPropagation()}>
                {message === "loader" ? <div className="loaderPositions"></div> : <h3>{message}</h3>}
                {txHash && (
                    <p> 
                        <a 
                            href={`https://basescan.org/tx/${txHash}`} 
                            target="_blank" 
                            rel="noopener noreferrer" 
                            className="tx-link"
                        >
                            {txHash.slice(0, 10)}...{txHash.slice(-10)}
                        </a>
                    </p>
                )}
                <button className="close-popup" onClick={onClose}>Close</button>
            </div>
        </div>
    );
};

export default InfoPopUp;