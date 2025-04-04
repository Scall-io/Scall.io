import React, { useState } from "react";

export default function HowItWorks() {
  const [fullscreenImg, setFullscreenImg] = useState(null);

  const openImage = (src) => {
    setFullscreenImg(src);
  };

  const closeImage = () => {
    setFullscreenImg(null);
  };

  return (
    <div className="how-it-works-container">
      <div className="how-it-works-header">
        <h1 className="how-it-works-title">How It Works</h1>
        <p className="how-it-works-subtitle">
          Scall.io is a decentralized perpetual option protocol. Whether you're a trader or liquidity provider, here's how you can interact with the platform.
        </p>
      </div>

      {/* Step Section - Opening a Perpetual Option */}
      <section className="how-it-works-section">
        <h2 className="section-title">Opening a Perpetual Option</h2>

        <div className="step">
          <h3 className="step-title">1. Deposit Collateral</h3>
          <p>
            Navigate to the <strong>Dashboard</strong> and deposit your USDC collateral. This collateral is required to open option contracts.<br/>
            A minimum of 2 weeks of rent must be deposited to initiate a position.
          </p>
          <div className="screenshot-placeholder">
            <img src="/screenshot1.png" alt="Deposit Collateral" onClick={() => openImage("/screenshot1.png")} />
          </div>
        </div>

        <div className="step">
          <h3 className="step-title">2. Open Your Position</h3>
          <p>
            Go to the <strong>Trade</strong> page, select your asset (e.g., BTC or ETH), then choose the type of option (Call or Put).
            The strike price is set to the nearest available level based on protocol liquidity. Enter the amount and review the rent cost.<br/>
            Confirm to open the position. Your collateral will start being used immediately.
          </p>
          <div className="screenshot-placeholder">
            <img src="/screenshot2.png" alt="Open Position" onClick={() => openImage("/screenshot2.png")} />
          </div>
        </div>

        <div className="step">
          <h3 className="step-title">3. View Your Position</h3>
          <p>
            Return to the <strong>Dashboard</strong> to track your open positions, rent cost, and potential profits.
          </p>
          <div className="screenshot-placeholder">
            <img src="/screenshot3.png" alt="View Position" onClick={() => openImage("/screenshot3.png")} />
          </div>
        </div>

        <div className="step">
          <h3 className="step-title">4. Close or Execute</h3>
          <p>
            You can close your position at any time. If your option is in profit, you can execute the contract to exchange assets at the strike price.
            Make sure the necessary asset is available in your wallet. Flashloan execution support will be available soon.<br/>
            If the position isn’t profitable, you can stop the contract by clicking <strong>Close</strong>.
          </p>
        </div>
      </section>

      <section className="how-it-works-section">
        <h2 className="section-title">Providing Liquidity</h2>

        <div className="step">
          <h3 className="step-title">1. Deposit Funds</h3>
          <p>
            Go to the <strong>Earn</strong> page and select the asset pair. Choose to provide either Calls (e.g., BTC) or Puts (USDC).
            Your funds will be matched to the nearest available strike price.<br/>
            An estimated weekly earnings value is displayed. Optionally, you can enable <strong>Auto Replace</strong> to move unused liquidity to the closest strike.
          </p>
          <div className="screenshot-placeholder">
            <img src="/screenshot4.png" alt="Provide Liquidity" onClick={() => openImage("/screenshot4.png")} />
          </div>
        </div>

        <div className="step">
          <h3 className="step-title">Additional Informations</h3>
          <p>
          If your liquidity is being used by traders, you won’t be able to withdraw those funds — or at least a portion of it. However, you can still exit by selling your position, which will continue to earn fees as long as it’s active.
          <br/><br/>
          Once the strike price is reached, your liquidity may be exchanged when traders execute their contracts.
          <br/><br/>
          You can implement strategies to hedge against different scenarios while maintaining exposure to the asset you originally deposited.
          </p>
        </div>

        <div className="step">
          <h3 className="step-title">2. Manage Your Liquidity</h3>
          <p>
            Visit the <strong>Dashboard</strong> to view all your LP positions. Track your earnings, toggle Auto Replace, or close positions.<br/>
            If funds are locked, you can still withdraw available assets. The locked part will continue generating fees.
          </p>
          <div className="screenshot-placeholder">
            <img src="/screenshot5.png" alt="Manage Liquidity" onClick={() => openImage("/screenshot5.png")} />
          </div>
        </div>
      </section>
      {fullscreenImg && (
        <div className="fullscreen-overlay" onClick={closeImage}>
          <img src={fullscreenImg} className="fullscreen-image" alt="Fullscreen" />
        </div>
      )}
    </div>
  );
}