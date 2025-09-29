// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract AggregatorV3Mock is AggregatorV3Interface {
    int256 public price;
    uint8 public decimals;
    
    constructor(int256 _price, uint8 _decimals) {
        price = _price;
        decimals = _decimals;
    }
    
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (0, price, 0, block.timestamp, 0);
    }
    
    function getRoundData(uint80) external pure returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        revert("Not implemented");
    }
    
    function description() external pure returns (string memory) {
        return "Mock Aggregator";
    }
    
    function version() external pure returns (uint256) {
        return 1;
    }
}