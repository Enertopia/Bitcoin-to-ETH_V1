const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const { deployMockContract } = waffle;
const AggregatorV3Interface = require("@chainlink/contracts/abi/v0.8/AggregatorV3Interface.json");

describe("PriceOracle Contract", function () {
    let priceOracle;
    let owner, addr1;
    let mockPriceFeed1, mockPriceFeed2;

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();

        // Deploy mock Chainlink price feeds
        mockPriceFeed1 = await deployMockContract(owner, AggregatorV3Interface);
        mockPriceFeed2 = await deployMockContract(owner, AggregatorV3Interface);

        await mockPriceFeed1.mock.latestRoundData.returns(0, ethers.utils.parseUnits("30000", 8), 0, 0, 0);
        await mockPriceFeed2.mock.latestRoundData.returns(0, ethers.utils.parseUnits("35000", 8), 0, 0, 0);

        // Deploy the PriceOracle contract
        const PriceOracle = await ethers.getContractFactory("PriceOracle");
        priceOracle = await PriceOracle.deploy([mockPriceFeed1.address, mockPriceFeed2.address]);
        await priceOracle.deployed();
    });

    it("Correctly aggregates prices from multiple feeds", async function () {
        const [aggregatedPrice, ] = await priceOracle.getAggregatedETHBTCPrice();
        expect(aggregatedPrice).to.equal(ethers.utils.parseUnits("32500", 8)); // The average of 30000 and 35000
    });

    it("Updates aggregated price when a new feed is added", async function () {
        const mockPriceFeed3 = await deployMockContract(owner, AggregatorV3Interface);
        await mockPriceFeed3.mock.latestRoundData.returns(0, ethers.utils.parseUnits("40000", 8), 0, 0, 0);

        await priceOracle.addPriceFeed(mockPriceFeed3.address); // Assuming addPriceFeed is a function in PriceOracle

        const [newAggregatedPrice, ] = await priceOracle.getAggregatedETHBTCPrice();
        expect(newAggregatedPrice).to.equal(ethers.utils.parseUnits("35000", 8)); // The new average of 30000, 35000, and 40000
    });

    it("Handles removal of a price feed", async function () {
        await priceOracle.removePriceFeed(mockPriceFeed1.address); // Assuming removePriceFeed is a function in PriceOracle

        const [updatedAggregatedPrice, ] = await priceOracle.getAggregatedETHBTCPrice();
        expect(updatedAggregatedPrice).to.equal(ethers.utils.parseUnits("35000", 8)); // Only feed2 remains, so its price is the "aggregated" price
    });

    // Additional tests can include error cases, permission checks, etc.
});
