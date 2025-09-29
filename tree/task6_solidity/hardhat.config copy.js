require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-deploy")

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",

  networks:{
    localhost:{
      url: "http://127.0.0.1:8545",
    },
    // sepolia:{
    //   url: "https://sepolia.infura.io/v3/YOUR-PROJECT-ID",
    //   accounts: ["YOUR-PRIVATE-KEY"],
    // }
  },
  namedAccounts:{
    deployer:{
      default:0,
    }
  },
  // etherscan:{
  //   apiKey:""
  // }
};
