// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChainlinkAdapter is Ownable {
    // Array of Chainlink Price Feeds (ETH-BTC)
    AggregatorV3Interface[] private priceFeeds;

    // Event declarations for adding and removing price feeds
    event PriceFeedAdded(address indexed feedAddress);
    event PriceFeedRemoved(address indexed feedAddress);

    constructor(AggregatorV3Interface[] memory _initialFeeds) {
        for (uint256 i = 0; i < _initialFeeds.length; i++) {
            _addPriceFeed(_initialFeeds[i]);
        }
    }

    // Public function to fetch the aggregated price from multiple feeds
    function getAggregatedPrice() public view returns (uint256 aggregatedPrice, uint256 latestTimestamp) {
        require(priceFeeds.length > 0, "No price feeds available");

        uint256 priceSum = 0;
        uint256 count = 0;
        latestTimestamp = 0;

        for (uint256 i = 0; i < priceFeeds.length; i++) {
            (
                uint80 roundID, 
                int256 price,
                uint256 startedAt,
                uint256 timeStamp,
                uint80 answeredInRound
            ) = priceFeeds[i].latestRoundData();

            if (price > 0 && timeStamp > latestTimestamp) {
                priceSum += uint256(price);
                count++;
                latestTimestamp = timeStamp;
            }
        }

        require(count > 0, "No valid data from price feeds");
        aggregatedPrice = priceSum / count;
    }

    // Owner-only function to add a new price feed
    function addPriceFeed(AggregatorV3Interface _feed) public onlyOwner {
        _addPriceFeed(_feed);
    }

    // Owner-only function to remove a price feed by address
    function removePriceFeedByAddress(address _feedAddress) public onlyOwner {
        for (uint256 i = 0; i < priceFeeds.length; i++) {
            if (address(priceFeeds[i]) == _feedAddress) {
                _removePriceFeedAtIndex(i);
                return;
            }
        }
        revert("Feed address not found");
    }

    // Internal function to add a price feed to the array
    function _addPriceFeed(AggregatorV3Interface _feed) internal {
        require(address(_feed) != address(0), "Invalid feed address");
        priceFeeds.push(_feed);
        emit PriceFeedAdded(address(_feed));
    }

    // Internal function to remove a price feed from the array by index
    function _removePriceFeedAtIndex(uint256 index) internal {
        require(index < priceFeeds.length, "Invalid index for removal");
        emit PriceFeedRemoved(address(priceFeeds[index]));
        priceFeeds[index] = priceFeeds[priceFeeds.length - 1];
        priceFeeds.pop();
    }
}
