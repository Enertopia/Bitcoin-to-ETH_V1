const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployMockContract } = require("@ethereum-waffle/mock-contract");
const AggregatorV3Interface = require("@chainlink/contracts/abi/v0.8/AggregatorV3Interface.json");

describe("ETH-BTC Swap Integration Tests", function () {
    let owner, user;
    let ethereumSwap, priceOracle;
    let mockPriceFeed;
    const initialRate = "50000"; // ETH-BTC initial mock rate

    beforeEach(async function () {
        [owner, user] = await ethers.getSigners();

        // Deploy the mock Chainlink price feed with initial rate
        mockPriceFeed = await deployMockContract(owner, AggregatorV3Interface.abi);
        await mockPriceFeed.mock.latestRoundData.returns(0, ethers.utils.parseUnits(initialRate, 8), 0, 0, 0);

        // Deploy PriceOracle contract with mock price feed address
        const PriceOracle = await ethers.getContractFactory("PriceOracle");
        priceOracle = await PriceOracle.deploy([mockPriceFeed.address]);
        await priceOracle.deployed();

        // Deploy EthereumSwap contract with PriceOracle address
        const EthereumSwap = await ethers.getContractFactory("EthereumSwap");
        ethereumSwap = await EthereumSwap.deploy(priceOracle.address);
        await ethereumSwap.deployed();
    });

    it("should accurately lock ETH and initiate swap with correct ETH-BTC rate", async function () {
        const ethToLock = ethers.utils.parseEther("1"); // 1 ETH
        await user.sendTransaction({
            to: ethereumSwap.address,
            value: ethToLock,
        });

        // Assert ETH locked by checking contract's ETH balance
        expect(await ethers.provider.getBalance(ethereumSwap.address)).to.equal(ethToLock);

        // Fetch current ETH-BTC rate and calculate expected BTC amount
        const [rate,] = await priceOracle.getAggregatedETHBTCPrice();
        const expectedBtcAmount = ethToLock.mul(rate).div(ethers.utils.parseUnits("1", 8));

        // Initiate the swap and verify event emission
        await expect(ethereumSwap.connect(user).initiateSwap(ethToLock))
            .to.emit(ethereumSwap, "SwapInitiated")
            .withArgs(user.address, ethToLock, expectedBtcAmount);
    });

    it("updates swap rate correctly on price feed update", async function () {
        const newRate = "55000"; // Updated ETH-BTC rate
        await mockPriceFeed.mock.latestRoundData.returns(0, ethers.utils.parseUnits(newRate, 8), 0, 0, 0);

        const [updatedRate,] = await priceOracle.getAggregatedETHBTCPrice();
        expect(updatedRate).to.equal(ethers.utils.parseUnits(newRate, 8));
    });

    it("reverts swap if insufficient ETH locked", async function () {
        const insufficientEthToLock = ethers.utils.parseEther("0.5"); // Attempting to swap with less ETH locked
        await user.sendTransaction({
            to: ethereumSwap.address,
            value: insufficientEthToLock,
        });

        // Attempt to initiate swap with more ETH than locked
        await expect(ethereumSwap.connect(user).initiateSwap(ethers.utils.parseEther("1")))
            .to.be.revertedWith("Insufficient balance");
    });

    // More tests here: simulate price changes, incorrect inputs, edge cases, etc.
});
