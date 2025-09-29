// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAuctionFactor {
    function getPrice(address tokenAddress) external view returns (int256);
    function setPriceFeed(address tokenAddress, address priceFeedAddress) external;
}