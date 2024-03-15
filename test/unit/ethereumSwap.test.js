const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployMockContract } = require("ethereum-waffle");
const IAdvancedPriceOracle = require("../artifacts/contracts/IAdvancedPriceOracle.sol/IAdvancedPriceOracle.json");

describe("EthereumSwap Contract", function () {
    let ethereumSwap;
    let priceOracleMock;
    let owner;
    let user1;
    let ethAmount = ethers.utils.parseEther("1"); // 1 ETH for testing
    let initialETHBTCPrice = 50000; // Example initial price

    beforeEach(async function () {
        [owner, user1] = await ethers.getSigners();
        
        // Deploy a mock Chainlink Price Oracle
        priceOracleMock = await deployMockContract(owner, IAdvancedPriceOracle.abi);
        await priceOracleMock.mock.getAggregatedETHBTCPrice.returns(ethers.utils.parseUnits(initialETHBTCPrice.toString(), 8), Math.floor(Date.now() / 1000));

        // Deploy the EthereumSwap contract with the price oracle mock
        const EthereumSwap = await ethers.getContractFactory("EthereumSwap");
        ethereumSwap = await EthereumSwap.deploy(priceOracleMock.address);
        await ethereumSwap.deployed();
    });

    it("Should successfully lock ETH", async function () {
        await expect(user1.sendTransaction({
            to: ethereumSwap.address,
            value: ethAmount,
        })).to.changeEtherBalances([user1, ethereumSwap], [ethAmount.mul(-1), ethAmount]);
    });

    it("Should fetch the correct ETH-BTC swap rate from the oracle", async function () {
        const [price,] = await ethereumSwap.getAggregatedETHBTCPrice();
        expect(price).to.equal(ethers.utils.parseUnits(initialETHBTCPrice.toString(), 8));
    });

    it("Should initiate a swap based on the oracle price", async function () {
        await user1.sendTransaction({
            to: ethereumSwap.address,
            value: ethAmount,
        });

        await expect(ethereumSwap.connect(user1).initiateSwap(ethAmount))
            .to.emit(ethereumSwap, "SwapInitiated")
            .withArgs(user1.address, ethAmount, initialETHBTCPrice);
    });

    it("Should revert if trying to initiate a swap without sufficient locked ETH", async function () {
        const insufficientAmount = ethers.utils.parseEther("2"); // Attempting to swap 2 ETH without depositing
        await expect(ethereumSwap.connect(user1).initiateSwap(insufficientAmount))
            .to.be.revertedWith("Insufficient balance");
    });

    // Add more tests as necessary for edge cases and failure modes
});
