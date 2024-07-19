import { HardhatUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-typechain";
import "hardhat-deploy";
import "solidity-coverage";
import "@openzeppelin/hardhat-upgrades";
import { config as dotEnvConfig } from "dotenv";

dotEnvConfig();

const INFURA_API_KEY = process.env.INFURA_API_KEY || "";
const SEPOLIA_PRIVATE_KEY =
  process.env.SEPOLIA_PRIVATE_KEY ||
  "0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3"; // well known private key
const { ETHERSCAN_API_KEY } = process.env;

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    compilers: [
      {
        version: "0.8.20",
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://ethereum-sepolia.rpc.subquery.network/public/"
      },
      accounts: [{ privateKey: SEPOLIA_PRIVATE_KEY, balance: "100000000000000000000" }],
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    sepolia: {
      url: "https://ethereum-sepolia.rpc.subquery.network/public/",
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    coverage: {
      url: "http://127.0.0.1:8555",
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};

export default config;
