// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IAdvancedPriceOracle.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkPriceOracle is IAdvancedPriceOracle {
    address public owner;
    AggregatorV3Interface[] private priceFeeds;
    mapping(address => bool) private callbacks;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(AggregatorV3Interface[] memory _priceFeeds) {
        owner = msg.sender;
        priceFeeds = _priceFeeds;
    }

    function getAggregatedETHBTCPrice() external view override returns (uint256, uint256) {
        uint256 sumPrices = 0;
        uint256 validFeeds = 0;
        for(uint i = 0; i < priceFeeds.length; i++) {
            try priceFeeds[i].latestRoundData() returns (
                uint80, int256 price, , uint256 updatedAt, 
            ) {
                if(price > 0) {
                    sumPrices += uint256(price);
                    validFeeds++;
                }
            } catch {
                continue;
            }
        }
        require(validFeeds > 0, "No valid price feeds available");
        uint256 averagePrice = sumPrices / validFeeds;
        return (averagePrice, block.timestamp);
    }

    function registerPriceUpdateCallback(address callbackAddress) external override onlyOwner {
        require(callbackAddress != address(0), "Invalid callback address");
        callbacks[callbackAddress] = true;
    }

    function unregisterPriceUpdateCallback(address callbackAddress) external override onlyOwner {
        require(callbacks[callbackAddress], "Callback not registered");
        delete callbacks[callbackAddress];
    }

    // Additional functions to manage price feeds
    function addPriceFeed(AggregatorV3Interface _priceFeed) external onlyOwner {
        require(address(_priceFeed) != address(0), "Invalid price feed address");
        priceFeeds.push(_priceFeed);
    }

    function removePriceFeed(uint index) external onlyOwner {
        require(index < priceFeeds.length, "Invalid index");
        priceFeeds[index] = priceFeeds[priceFeeds.length - 1];
        priceFeeds.pop();
    }

    // Ownership management
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }
}
