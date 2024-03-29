require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-waffle")
require("./tasks/block-number");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
require("solidity-coverage");
require("hardhat-deploy");

// hardhat-toolbox already contains hardhat verify
// require("@nomicfoundation/hardhat-verify");

const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY;
const PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.7.6",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking: {
        // url: process.env.ALCHEMY_MAINNET_URL,
        url: process.env.ALCHEMY_OP_MAINNET_URL,
      },
    },
    localhost: {
      url: "http://localhost:8545",
      chainId: 31337,
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 11155111,
      gas: 4000000,
      gasPrice: 200000000000,
      // gasPrice: "auto",
      // gas: "auto",
      blockConfirmations: 3,
    },
    goerli: {
      url: process.env.GOERLI_RPC_URL,
      accounts: [process.env.GOERLI_PRIVATE_KEY],
      chainId: 5,
      gas: 2100000, //
      gasPrice: 12000000000, // 12 wei
      blockConfirmations: 3,
    },
    optism: {
      url: `https://opt-mainnet.g.alchemy.com/v2/8LQ6F_CKZvP5LrBgdTNySjZ_YaDh162T`,
      accounts: [process.env.OP_WALLET_PRIVATE_KEY],
      chainId: 10,
      gas: 2100000, //
      gasPrice: 12000000000, // 12 wei
      blockConfirmations: 3,
    },
    op_sepolia: {
      url: `https://opt-sepolia.g.alchemy.com/v2/HwtsQCroXMrbyMh1aQSU9TzoKaVludrW`,
      accounts: [process.env.OP_WALLET_PRIVATE_KEY],
      chainId: 11155420,
      gasPrice: "auto",
      gas: "auto",
      // gas: 2100000, //
      // gasPrice: 12000000000, // 12 wei
      blockConfirmations: 3,
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
    customChains: [
      {
        network: "op_sepolia",
        chainId: 11155420,
        urls: {
          apiURL: "https://sepolia-optimism.etherscan.io/api",
          browserURL: "https://sepolia-optimism.etherscan.io",
        },
      },
    ],
  },
  sourcify: {
    // Disabled by default
    // Doesn't need an API key
    enabled: true,
  },
  gasReporter: {
    enabled: false,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
    coinmarketcap: COINMARKETCAP_API_KEY,
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
  },
};
