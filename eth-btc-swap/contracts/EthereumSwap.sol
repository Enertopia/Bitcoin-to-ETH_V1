// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAdvancedPriceOracle.sol";

/**
 * @title EthereumSwap
 * @dev This contract enables ETH to BTC swaps using an external price oracle for the current exchange rate.
 * Created by Emiliano German Solazzi Griminger.
 */
contract EthereumSwap is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IAdvancedPriceOracle public priceOracle;
    uint256 public lastPriceUpdate;
    uint256 public currentETHBTCRate;
    mapping(address => uint256) public ethBalances;

    event RateUpdated(uint256 newRate, uint256 timestamp);
    event SwapInitiated(address indexed user, uint256 ethAmount, uint256 estimatedBTC);
    event ETHDeposited(address indexed depositor, uint256 amount);
    event ETHWithdrawn(address indexed withdrawer, uint256 amount);

    constructor(address _priceOracle) {
        require(_priceOracle != address(0), "EthereumSwap: Invalid price oracle address");
        priceOracle = IAdvancedPriceOracle(_priceOracle);
    }

    /**
     * @dev Updates the ETH to BTC swap rate using the provided price oracle.
     * Can only be called by the contract owner.
     */
    function updateSwapRate() public onlyOwner {
        (uint256 newRate, uint256 timestamp) = priceOracle.getAggregatedETHBTCPrice();
        require(timestamp > lastPriceUpdate, "EthereumSwap: Price data is not updated yet");
        currentETHBTCRate = newRate;
        lastPriceUpdate = timestamp;
        emit RateUpdated(newRate, timestamp);
    }

    /**
     * @dev Allows users to initiate an ETH to BTC swap.
     * @param _ethAmount The amount of ETH the user wants to swap.
     */
    function initiateSwap(uint256 _ethAmount) external nonReentrant {
        require(_ethAmount > 0 && _ethAmount <= ethBalances[msg.sender], "EthereumSwap: Invalid ETH amount");
        uint256 estimatedBTC = _ethAmount.mul(currentETHBTCRate).div(1e18); // Assuming ETHBTCRate is in 1e18 format for precision
        ethBalances[msg.sender] = ethBalances[msg.sender].sub(_ethAmount);
        // BTC credited logic (off-chain or via a tokenized representation) goes here
        emit SwapInitiated(msg.sender, _ethAmount, estimatedBTC);
    }

    /**
     * @dev Allows users to deposit ETH into the contract.
     */
    function depositETH() external payable {
        require(msg.value > 0, "EthereumSwap: Deposit amount must be greater than 0");
        ethBalances[msg.sender] = ethBalances[msg.sender].add(msg.value);
        emit ETHDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to withdraw their ETH from the contract.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 _amount) external {
        require(_amount <= ethBalances[msg.sender], "EthereumSwap: Insufficient balance");
        ethBalances[msg.sender] = ethBalances[msg.sender].sub(_amount);
        payable(msg.sender).transfer(_amount);
        emit ETHWithdrawn(msg.sender, _amount);
    }

    // Additional functions and improvements can be added here
}
