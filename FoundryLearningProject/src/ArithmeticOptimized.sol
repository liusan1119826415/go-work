// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArithmeticOptimized {
    // Optimized addition function using unchecked arithmetic for known safe operations
    function addUnchecked(uint256 a, uint256 b) public pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }
    
    // Standard addition function for comparison
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
    
    // Optimized subtraction with custom error to reduce bytecode size
    error NegativeResult();
    
    function subtractOptimized(uint256 a, uint256 b) public pure returns (uint256) {
        if (a < b) {
            revert NegativeResult();
        }
        unchecked {
            return a - b;
        }
    }
    
    // Standard subtraction function for comparison
    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        require(a >= b, "Subtraction would result in negative number");
        return a - b;
    }
    
    // Bit shifting optimization for powers of 2 multiplication
    function multiplyByPowerOfTwo(uint256 a, uint8 power) public pure returns (uint256) {
        return a << power; // Equivalent to a * 2^power
    }
    
    // Standard multiplication for comparison
    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }
    
    // Bit shifting optimization for powers of 2 division
    function divideByPowerOfTwo(uint256 a, uint8 power) public pure returns (uint256) {
        return a >> power; // Equivalent to a / 2^power
    }
    
    // Standard division function for comparison
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Division by zero is not allowed");
        return a / b;
    }
}