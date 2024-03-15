// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title IAdvancedPriceOracle
 * @dev Interface for advanced price oracle functionality, enabling ETH-BTC swap contracts to access
 * aggregated and timely price data from multiple decentralized sources.
 */
interface IAdvancedPriceOracle {
    /**
     * @notice Fetches the latest aggregated exchange rate for ETH to BTC.
     * @dev This method should return the exchange rate with appropriate scaling (e.g., 1e8 for BTC precision).
     * It aggregates price data from multiple sources to mitigate single point of failure and manipulation risks.
     * @return price The latest aggregated ETH-BTC exchange rate.
     * @return timestamp The Unix timestamp at which the price was last updated.
     */
    function getAggregatedETHBTCPrice() external view returns (uint256 price, uint256 timestamp);

    /**
     * @notice Registers a contract for receiving real-time price updates.
     * @dev The registered contract must implement a predefined callback interface to handle the updates.
     * This allows for dynamic response to market conditions in swap contracts.
     * @param callbackAddress The address of the contract where price updates will be sent.
     */
    function registerPriceUpdateCallback(address callbackAddress) external;

    /**
     * @notice Unregisters a contract from receiving real-time price updates.
     * @dev Can be used to manage subscriptions or in cases where a contract no longer needs to receive updates.
     * @param callbackAddress The address of the contract to unregister.
     */
    function unregisterPriceUpdateCallback(address callbackAddress) external;
}
