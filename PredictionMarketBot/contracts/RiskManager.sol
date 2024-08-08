// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title RiskManager
 * @dev Contract to handle risk management for the prediction market bot.
 */
contract RiskManager {
    address public owner;
    uint256 public maxBetAmount;
    uint256 public stopLossThreshold;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Sets the maximum bet amount.
     * @param _maxBetAmount The maximum bet amount.
     */
    function setMaxBetAmount(uint256 _maxBetAmount) external onlyOwner {
        maxBetAmount = _maxBetAmount;
    }

    /**
     * @notice Sets the stop-loss threshold.
     * @param _stopLossThreshold The stop-loss threshold.
     */
    function setStopLossThreshold(uint256 _stopLossThreshold) external onlyOwner {
        stopLossThreshold = _stopLossThreshold;
    }
}
