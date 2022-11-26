
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-gas-reporter";
require('dotenv').config({ path: './.env' });

console.log({
  priv: `0x${process.env.MUMBAI_PRIVATE_KEY1}`
})

export default {
  solidity: {
	version: "0.8.7",
	settings: {
		optimizer: {
			enabled: false,
			runs: 88888
		}
	}
  },
  networks: {
    goerli: {
      url: `${process.env.ALCHEMY_URL}`,
      accounts: [`0x${process.env.MUMBAI_PRIVATE_KEY1}`, `0x${process.env.MUMBAI_PRIVATE_KEY2}` ], 
      gas: 9900000,
      gasPrice: 8000000000
    },
    // mumbai: {
    //   url: `${process.env.ALCHEMY_URL}`,
    //   accounts: [`0x${process.env.MUMBAI_PRIVATE_KEY1}`, `0x${process.env.MUMBAI_PRIVATE_KEY2}` ], 
    //   gas: 9900000,
    //   gasPrice: 8000000000
    // }
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY,
 },
  mocha: {
    timeout: 2000000
  }
};