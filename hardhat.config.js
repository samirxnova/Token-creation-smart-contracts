require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const RPC_URL = process.env.RPC_URL;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.25",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  allowUnlimitedContractSize: true,
  
  etherscan: {
    apiKey: {
      // 0G chain doesn't require API key for verification yet
      "0g-testnet": "placeholder"
    },
    customChains: [
      {
        network: "0g-testnet",
        chainId: 16602,
        urls: {
          apiURL: "https://chainscan-galileo.0g.ai/api",
          browserURL: "https://chainscan-galileo.0g.ai"
        }
      }
    ]
  },
  
  networks: {
    hardhat: {
      chainId: 31337
    },
    
    "0g-testnet": {
      url: RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 16602,
      gasPrice: process.env.GAS_PRICE || 20000000000, // 20 gwei
      gas: process.env.GAS_LIMIT || 8000000,
      timeout: 60000,
      confirmations: 1
    }
  },
  
  // Mocha timeout for tests
  mocha: {
    timeout: 40000
  }
};

// 0G Network Configuration
// Network Name: 0G-Testnet-Galileo
// Chain ID: 16602
// RPC URL: https://evmrpc-testnet.0g.ai
// Explorer: https://explorer-testnet.0g.ai
// Chain Scanner: https://chainscan-galileo.0g.ai
// 
// Usage:
// Deploy to 0G testnet: npx hardhat run scripts/deploy.js --network 0g-testnet
// Verify contract: npx hardhat verify --network 0g-testnet <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>