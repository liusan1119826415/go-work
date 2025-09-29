require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-deploy");
require("@chainlink/hardhat-chainlink");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",

  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
     // chainId: 31337
    },
    // sepolia: {
    //   url: "https://sepolia.infura.io/v3/YOUR-PROJECT-ID",
    //   accounts: ["YOUR-PRIVATE-KEY"],
    //   chainSelector: 16015286601757825753 // Sepolia chain selector
    // },
    // mumbai: {
    //   url: "https://polygon-mumbai.infura.io/v3/YOUR-PROJECT-ID",
    //   accounts: ["YOUR-PRIVATE-KEY"],
    //   chainSelector: 12532609583862916517 // Mumbai chain selector
    // }
  },
  namedAccounts: {
    deployer: {
      default: 0,
    }
  },
  // chainlink: {
  //   ccip: {
  //     router: {
  //       sepolia: "0x0BF3dE8c5D3E8A2B34D2BEeB17ABFCeBaf363A59",
  //       mumbai: "0x1035CabC275068e0F4b745A29CEDf38E13aF41b1"
  //     }
  //   }
  // },
  // etherscan: {
  //   apiKey: {
  //     sepolia: "YOUR-ETHERSCAN-API-KEY",
  //     polygonMumbai: "YOUR-POLYGONSCAN-API-KEY"
  //   }
  // }
};
