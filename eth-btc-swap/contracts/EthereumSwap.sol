// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IPriceOracle {
    function getLatestETHBTCPrice() external view returns (uint256);
}

contract EthereumSwap is ReentrancyGuard {
    using SafeMath for uint256;

    // State variables
    address private owner;
    IPriceOracle public priceOracle;

    uint256 public totalLocked;
    mapping(address => uint256) public balances;

    // Events
    event ETHLocked(address indexed sender, uint256 amount, uint256 timestamp);
    event ETHBTCSwapInitiated(address indexed sender, uint256 ethAmount, uint256 estimatedBTC, uint256 timestamp);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event OracleChanged(address indexed oldOracle, address indexed newOracle);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "EthereumSwap: Caller is not the owner");
        _;
    }

    // Constructor
    constructor(address _priceOracle) {
        require(_priceOracle != address(0), "EthereumSwap: Invalid price oracle address");
        owner = msg.sender;
        priceOracle = IPriceOracle(_priceOracle);
    }

    // Functions
    function lockETH() external payable nonReentrant {
        require(msg.value > 0, "EthereumSwap: ETH amount is zero");
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        totalLocked = totalLocked.add(msg.value);
        emit ETHLocked(msg.sender, msg.value, block.timestamp);
    }

    function initiateSwap(uint256 _ethAmount) external nonReentrant {
        require(_ethAmount > 0, "EthereumSwap: ETH amount is zero");
        require(balances[msg.sender] >= _ethAmount, "EthereumSwap: Insufficient balance");
        
        // Subtract the ETH amount from the user's balance
        balances[msg.sender] = balances[msg.sender].sub(_ethAmount);
        totalLocked = totalLocked.sub(_ethAmount);

        // Estimate BTC amount
        uint256 ethPrice = priceOracle.getLatestETHBTCPrice();
        uint256 estimatedBTC = _ethAmount.mul(ethPrice).div(1e18); // Assuming the price is in 18 decimals

        emit ETHBTCSwapInitiated(msg.sender, _ethAmount, estimatedBTC, block.timestamp);

        // Further logic to handle cross-chain swap will be added here
    }

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "EthereumSwap: New owner is the zero address");
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    function updatePriceOracle(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "EthereumSwap: New oracle is the zero address");
        emit OracleChanged(address(priceOracle), _newOracle);
        priceOracle = IPriceOracle(_newOracle);
    }

    // View functions
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
}
