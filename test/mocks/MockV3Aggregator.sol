// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Chainlink AggregatorV3 mock for local and fork tests (Person 2 — gTurboflex).
contract MockV3Aggregator {
    int256 public answer;
    uint80 public roundId;
    uint256 public startedAt;
    uint256 public updatedAt;
    uint80 public answeredInRound;

    constructor(int256 initialAnswer) {
        answer = initialAnswer;
        roundId = 1;
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 1;
    }

    function setRoundData(uint80 newRoundId, int256 newAnswer, uint256 newUpdatedAt, uint80 newAnsweredInRound)
        external
    {
        roundId = newRoundId;
        answer = newAnswer;
        updatedAt = newUpdatedAt;
        answeredInRound = newAnsweredInRound;
        startedAt = newUpdatedAt;
    }

    function setAnswer(int256 newAnswer) external {
        answer = newAnswer;
        roundId += 1;
        updatedAt = block.timestamp;
        startedAt = updatedAt;
        answeredInRound = roundId;
    }

    function latestRoundData()
        external
        view
        returns (uint80 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint80 _answeredInRound)
    {
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}
