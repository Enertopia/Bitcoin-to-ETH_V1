// SPDX-License-Identifier: MIT
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    const deployer = (await hre.ethers.getSigners())[0];
    console.log("Deploying contracts with the account:", deployer.address);

    // Example: Deploying a ChainlinkAdapter contract
    const ChainlinkAdapter = await hre.ethers.getContractFactory("ChainlinkAdapter");
    const chainlinkPriceFeeds = getChainlinkPriceFeeds(hre.network.name);
    const chainlinkAdapter = await ChainlinkAdapter.deploy(chainlinkPriceFeeds);

    await chainlinkAdapter.deployed();
    console.log("ChainlinkAdapter deployed to:", chainlinkAdapter.address);

    // Saving contract artifacts for the frontend
    saveFrontendFiles({
        ChainlinkAdapter: { address: chainlinkAdapter.address, abi: ChainlinkAdapter.interface.format('json') },
    }, hre.network.name);

    // Wait for Etherscan to index the contract
    console.log("Waiting for Etherscan to index the contract...");
    await delay(60000); // Wait for 60 seconds

    // Verifying the contract on Etherscan
    console.log("Verifying contract on Etherscan...");
    try {
        await hre.run("verify:verify", {
            address: chainlinkAdapter.address,
            constructorArguments: [chainlinkPriceFeeds],
        });
    } catch (error) {
        console.error("Failed to verify contract on Etherscan:", error.message);
    }
}

function getChainlinkPriceFeeds(networkName) {
    // Define Chainlink price feeds for different networks
    const feeds = {
        rinkeby: [/* Rinkeby price feed addresses */],
        mainnet: [/* Mainnet price feed addresses */],
        // Add more networks as needed
    };
    return feeds[networkName] || [];
}

function saveFrontendFiles(contracts, networkName) {
    const dir = path.resolve(__dirname, '..', 'frontend', 'src', 'contracts', networkName);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    for (const [name, data] of Object.entries(contracts)) {
        fs.writeFileSync(path.join(dir, `${name}.json`), JSON.stringify(data, null, 2));
        console.log(`Saved ${name} contract artifacts for frontend at ${path.join(dir, `${name}.json`)}`);
    }
}

function delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
    console.error("Deployment script failed:", error);
    process.exit(1);
});
