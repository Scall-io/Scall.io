import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { ConnectButton } from '@rainbow-me/rainbowkit';

export default function NavBar() {
  const [menuVisible, setMenuVisible] = useState(false);
  const [tradeDropdown, setTradeDropdown] = useState(false);
  const [earnDropdown, setEarnDropdown] = useState(false);
  const navigate = useNavigate();

  const toggleMenu = () => {
    setMenuVisible(!menuVisible);
  };

  return (
    <div>
      <div className="navbar-phone">
        {/* Toggle button */}
        <button className="nav-toggle-button" onClick={toggleMenu}>
          ☰
        </button>

        {/* Sliding menu */}
        <div className={`modern-menu ${menuVisible ? "active" : ""}`}>
          <button className="close-button" onClick={toggleMenu}>×</button>
          <Link to="/" className="logo" onClick={toggleMenu}><img src="/logo.png" alt="Logo" className="logo-img" /></Link>
          <div className="dropdown">
            <button className="nav-link dropdown-button" onClick={() => setTradeDropdown(!tradeDropdown)}>Trade</button>
            {tradeDropdown && (
              <div className="dropdown-content">
                <button onClick={() => navigate("/market/BTC")}>BTC</button>
                <button onClick={() => navigate("/market/ETH")}>ETH</button>
              </div>
            )}
          </div>
          <div className="dropdown">
            <button className="nav-link dropdown-button" onClick={() => setEarnDropdown(!earnDropdown)}>Earn</button>
            {earnDropdown && (
              <div className="dropdown-content">
                <button onClick={() => navigate("/earn/BTC_USDC")}>BTC-USDC</button>
                <button onClick={() => navigate("/earn/ETH_USDC")}>ETH-USDC</button>
              </div>
            )}
          </div>
          <Link to="/dashboard" className="nav-link" onClick={toggleMenu}>Dashboard</Link>
          <Link to="/how-it-works" className="nav-link" onClick={toggleMenu}>How it Works</Link>  
          <ConnectButton />
        </div>
      </div>
      <nav className="navbar">
        <div className="nav-left">
          <Link to="/" className="logo"><img src="/logo.png" alt="Logo" className="logo-img" /></Link>
          <div 
            className="dropdown" 
            onMouseEnter={() => setTradeDropdown(true)} 
            onMouseLeave={() => setTradeDropdown(false)}
          >
            <button className="nav-link dropdown-button">Trade</button>
            {tradeDropdown && (
              <div className="dropdown-content">
                <button onClick={() => navigate("/market/BTC")}>BTC</button>
                <button onClick={() => navigate("/market/ETH")}>ETH</button>
              </div>
            )}
          </div>
          <div 
            className="dropdown" 
            onMouseEnter={() => setEarnDropdown(true)} 
            onMouseLeave={() => setEarnDropdown(false)}
          >
            <button className="nav-link dropdown-button">Earn</button>
            {earnDropdown && (
              <div className="dropdown-content">
                <button onClick={() => navigate("/earn/BTC_USDC")}>BTC - USDC</button>
                <button onClick={() => navigate("/earn/ETH_USDC")}>ETH - USDC</button>
              </div>
            )}
          </div>
          <Link to="/dashboard" className="nav-link">Dashboard</Link>
          <Link to="/how-it-works" className="nav-link">How it Works</Link>          
        </div>
        <div className="nav-right">
            <ConnectButton />
        </div>
      </nav>
      
    </div>
    
  );
}