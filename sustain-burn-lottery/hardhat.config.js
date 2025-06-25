require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

const { PRIVATE_KEY, BASE_RPC_URL, ETHERSCAN_KEY } = process.env;

module.exports = {
  solidity: "0.8.24",
  networks: {
    base: {
      url: BASE_RPC_URL ?? "",
      accounts: [PRIVATE_KEY],
      chainId: 8453            // Base main-net
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_KEY      // Basescan also uses Etherscan keys
  }
};
