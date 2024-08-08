// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {BettingStrategy} from "./BettingStrategy.sol";
import {RiskManager} from "./RiskManager.sol";
import {MarketEventFetcher} from "./MarketEventFetcher.sol";
import {Governance} from "./Governance.sol";

/**
 * @title PredictionMarketBot
 * @dev A bot that participates in prediction markets based on predefined strategies and data inputs.
 */
contract PredictionMarketBot {
    using SafeERC20 for IERC20;

    address public owner;
    IERC20 public immutable predictionMarketToken;
    AggregatorV3Interface public priceFeed;

    BettingStrategy public bettingStrategy;
    RiskManager public riskManager;
    MarketEventFetcher public marketEventFetcher;
    Governance public governance;

    struct Bet {
        uint256 eventId;
        uint256 amount;
        bool outcome;
        bool active;
    }

    struct PerformanceMetric {
        uint256 totalBets;
        uint256 successfulBets;
        uint256 totalProfit;
    }

    PerformanceMetric public metrics;
    Bet[] public activeBets;

    event MarketEventFetched(uint256 indexed eventId, string description);
    event BetPlaced(uint256 indexed eventId, uint256 amount, bool outcome);
    event PositionAdjusted(uint256 indexed eventId, uint256 newPosition, bool newOutcome);
    event BetResult(uint256 indexed betId, bool success, uint256 profit);
    event TokensWithdrawn(address to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract with the given parameters.
     * @param _predictionMarketToken Address of the token used in the prediction market.
     * @param _priceFeed Address of the Chainlink price feed.
     * @param _bettingStrategy Address of the betting strategy contract.
     * @param _riskManager Address of the risk manager contract.
     * @param _marketEventFetcher Address of the market event fetcher contract.
     * @param _governance Address of the governance contract.
     */
    constructor(
        address _predictionMarketToken, 
        address _priceFeed, 
        address _bettingStrategy, 
        address _riskManager, 
        address _marketEventFetcher,
        address _governance
    ) {
        owner = msg.sender;
        predictionMarketToken = IERC20(_predictionMarketToken);
        priceFeed = AggregatorV3Interface(_priceFeed);
        bettingStrategy = BettingStrategy(_bettingStrategy);
        riskManager = RiskManager(_riskManager);
        marketEventFetcher = MarketEventFetcher(_marketEventFetcher);
        governance = Governance(_governance);
    }

    /**
     * @notice Fetches market events from the prediction market.
     */
    function fetchMarketEvents() external onlyOwner {
        marketEventFetcher.fetchMarketEvents();
    }

    /**
     * @notice Places a bet on a specific market event.
     * @param eventId The ID of the market event.
     * @param amount The amount of tokens to bet.
     * @param outcome The predicted outcome (true or false).
     */
    function placeBet(uint256 eventId, uint256 amount, bool outcome) public onlyOwner {
        require(amount > 0, "Bet amount must be greater than zero");
        require(amount <= riskManager.maxBetAmount(), "Bet amount exceeds maximum limit");

        predictionMarketToken.safeTransferFrom(msg.sender, address(this), amount);
        activeBets.push(Bet(eventId, amount, outcome, true));
        emit BetPlaced(eventId, amount, outcome);
    }

    /**
     * @notice Adjusts the position based on market sentiment.
     * @param eventId The ID of the market event.
     * @param newPosition The new amount to adjust the position to.
     * @param newOutcome The new predicted outcome.
     */
    function adjustPosition(uint256 eventId, uint256 newPosition, bool newOutcome) external onlyOwner {
        require(newPosition > 0, "New position amount must be greater than zero");

        emit PositionAdjusted(eventId, newPosition, newOutcome);
    }

    /**
     * @notice Fetches the latest price from the Chainlink price feed.
     * @return int256 The latest price.
     */
    function getLatestPrice() public view returns (int256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * @notice Withdraws tokens from the contract.
     * @param to The address to send the tokens to.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawTokens(address to, uint256 amount) external onlyOwner {
        predictionMarketToken.safeTransfer(to, amount);
        emit TokensWithdrawn(to, amount);
    }

    /**
     * @dev Transfers ownership of the contract to a new owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Updates the performance metrics after each bet.
     * @param success Whether the bet was successful.
     * @param profit The profit made from the bet.
     */
    function updateMetrics(bool success, uint256 profit) internal {
        metrics.totalBets += 1;
        if (success) {
            metrics.successfulBets += 1;
            metrics.totalProfit += profit;
        }
        emit BetResult(activeBets.length - 1, success, profit);
    }

    /**
     * @notice Places a bet automatically based on predefined conditions.
     * @param eventId The ID of the market event.
     * @param condition The condition to trigger the bet.
     */
    function automatedBet(uint256 eventId, bool condition) external onlyOwner {
        if (condition) {
            uint256 amount = bettingStrategy.calculateBetAmount();
            bool outcome = bettingStrategy.determineOutcome();
            placeBet(eventId, amount, outcome);
        }
    }

    /**
     * @notice Returns the details of active bets.
     * @return An array of active bet details.
     */
    function getActiveBets() external view returns (Bet[] memory) {
        return activeBets;
    }

    /**
     * @notice Returns the result of a specific bet.
     * @param betId The ID of the bet.
     * @return The result of the bet.
     */
    function getBetResult(uint256 betId) external view returns (bool) {
        // Return bet result logic
    }
}
