// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EnhancedChainlinkAggregatedPriceOracle
 * @dev Aggregates price data from multiple Chainlink oracles to provide a robust ETH-BTC exchange rate.
 * Coded by Emiliano German Solazzi Griminger.
 */
contract EnhancedChainlinkAggregatedPriceOracle is Ownable {
    AggregatorV3Interface[] public priceFeeds;
    
    event PriceFeedAdded(address indexed feedAddress);
    event PriceFeedRemoved(address indexed feedAddress);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor(AggregatorV3Interface[] memory _priceFeeds) {
        for(uint i = 0; i < _priceFeeds.length; i++) {
            require(address(_priceFeeds[i]) != address(0), "Invalid price feed address");
            priceFeeds.push(_priceFeeds[i]);
            emit PriceFeedAdded(address(_priceFeeds[i]));
        }
    }

    /**
     * @notice Fetches the latest aggregated exchange rate for ETH to BTC.
     * @dev Averages prices from multiple Chainlink feeds. Ensures at least one valid feed is present.
     * @return averagePrice The latest aggregated ETH-BTC exchange rate.
     * @return timestamp The Unix timestamp of the last update.
     */
    function getAggregatedETHBTCPrice() public view returns (uint256 averagePrice, uint256 timestamp) {
        uint256 sumPrices = 0;
        uint256 validFeeds = 0;
        uint256 latestUpdateTime = 0;

        for(uint i = 0; i < priceFeeds.length; i++) {
            try priceFeeds[i].latestRoundData() returns (, int256 price, , uint256 updatedAt,) {
                if(price > 0 && updatedAt > latestUpdateTime) {
                    sumPrices += uint256(price);
                    validFeeds++;
                    latestUpdateTime = updatedAt;
                }
            } catch {
                continue;
            }
        }

        require(validFeeds > 0, "No valid price feeds available");
        return (sumPrices / validFeeds, latestUpdateTime);
    }

    /**
     * @notice Adds a new Chainlink price feed to the aggregator.
     * @param _priceFeed The address of the new Chainlink price feed.
     */
    function addPriceFeed(AggregatorV3Interface _priceFeed) public onlyOwner {
        require(address(_priceFeed) != address(0), "Invalid price feed address");
        priceFeeds.push(_priceFeed);
        emit PriceFeedAdded(address(_priceFeed));
    }

    /**
     * @notice Removes a Chainlink price feed from the aggregator.
     * @param index The index of the price feed to remove.
     */
    function removePriceFeed(uint index) public onlyOwner {
        require(index < priceFeeds.length, "Invalid index");
        emit PriceFeedRemoved(address(priceFeeds[index]));
        priceFeeds[index] = priceFeeds[priceFeeds.length - 1];
        priceFeeds.pop();
    }
}
