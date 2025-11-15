// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Arithmetic {
    // Basic addition function
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
    
    // Basic subtraction function
    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        require(a >= b, "Subtraction would result in negative number");
        return a - b;
    }
    
    // Basic multiplication function
    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }
    
    // Basic division function
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Division by zero is not allowed");
        return a / b;
    }
}