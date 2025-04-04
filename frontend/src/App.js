import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import HowItWorks from "./components/HowItWorks";
import Dashboard from "./components/Dashboard";
import BTC_USDC from "./components/earn/BTC_USDC";
import ETH_USDC from "./components/earn/ETH_USDC";
import BTC from "./components/market/BTC";
import ETH from "./components/market/ETH";
import NavBar from "./components/NavBar";
import "./style.css";

// RainbowKit
import '@rainbow-me/rainbowkit/styles.css';
import { getDefaultConfig, RainbowKitProvider } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { base } from 'wagmi/chains';
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";
const config = getDefaultConfig({
  appName: 'Scall.io',
  projectId: '001',
  chains: [/*mainnet, polygon, optimism, arbitrum, */base],
});
const queryClient = new QueryClient();

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <Router>
            <div className="app-container">
              <NavBar />
              <div className="main-body">
                <Routes>
                  <Route path="/how-it-works" element={<HowItWorks />} />
                  <Route path="/dashboard" element={<Dashboard />} />
                  <Route path="/earn/ETH_USDC" element={<ETH_USDC />} />
                  <Route path="/earn/BTC_USDC" element={<BTC_USDC />} />
                  <Route path="/" element={<BTC />} />
                  <Route path="/market/BTC" element={<BTC />} />
                  <Route path="/market/ETH" element={<ETH />} />
                </Routes>
              </div>
            </div>
          </Router>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default App;

