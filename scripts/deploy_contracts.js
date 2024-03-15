// SPDX-License-Identifier: MIT
const hre = require("hardhat");
const { ethers } = hre;
const fs = require('fs');
const path = require('path');

// Chainlink ETH-BTC Price Feed addresses for different networks
// Ensure these are correctly set for your target networks
const chainlinkPriceFeedsByNetwork = {
  mainnet: [
    "0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c", // Example Mainnet address, replace with real ones
    // Add more as necessary
  ],
  rinkeby: [
    "0xECe365B379E1dD183B20fc5f022230C044d51404", // Example Rinkeby address, replace with real ones
    // Add more as necessary
  ],
  // Define other networks as needed
};

async function main() {
  const network = hre.network.name;
  const priceFeeds = chainlinkPriceFeedsByNetwork[network];
  if (!priceFeeds) {
    throw new Error(`No Chainlink Price Feed addresses configured for network: ${network}`);
  }

  // Deploying ChainlinkAdapter
  console.log("Deploying ChainlinkAdapter...");
  const ChainlinkAdapter = await ethers.getContractFactory("ChainlinkAdapter");
  const chainlinkAdapter = await ChainlinkAdapter.deploy(priceFeeds);
  await chainlinkAdapter.deployed();
  console.log(`ChainlinkAdapter deployed to: ${chainlinkAdapter.address}`);

  // Save deployed addresses to a file for easy access
  saveDeployedAddresses(network, {
    ChainlinkAdapter: chainlinkAdapter.address,
  });

  // Optional: Verify the contract on Etherscan after deployment
  if (process.env.ETHERSCAN_API_KEY) {
    await hre.run("verify:verify", {
      address: chainlinkAdapter.address,
      constructorArguments: [priceFeeds],
    });
    console.log("Verification submitted to Etherscan");
  } else {
    console.log("ETHERSCAN_API_KEY not set, skipping Etherscan verification.");
  }
}

function saveDeployedAddresses(network, addresses) {
  const filePath = path.join(__dirname, '..', 'deployedAddresses.json');
  let data = {};
  if (fs.existsSync(filePath)) {
    data = JSON.parse(fs.readFileSync(filePath));
  }
  data[network] = addresses;
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
  console.log(`Deployed addresses saved to ${filePath}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
