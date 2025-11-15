// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Arithmetic} from "../src/Arithmetic.sol";
import {ArithmeticOptimized} from "../src/ArithmeticOptimized.sol";

contract GasTest is Test {
    Arithmetic public arithmetic;
    ArithmeticOptimized public arithmeticOptimized;

    function setUp() public {
        arithmetic = new Arithmetic();
        arithmeticOptimized = new ArithmeticOptimized();
    }

    // 测试普通加法的 gas 消耗
    function testGas_Add() public {
        arithmetic.add(100, 200);
    }

    // 测试优化版加法的 gas 消耗
    function testGas_AddOptimized() public {
        arithmeticOptimized.add(100, 200);
    }

    // 测试普通减法的 gas 消耗
    function testGas_Subtract() public {
        arithmetic.subtract(500, 300);
    }

    // 测试优化版减法的 gas 消耗
    function testGas_SubtractOptimized() public {
        arithmeticOptimized.subtract(500, 300);
        arithmeticOptimized.subtractOptimized(500, 300);
    }

    // 测试普通乘法的 gas 消耗
    function testGas_Multiply() public {
        arithmetic.multiply(10, 20);
    }

    // 测试优化版乘法的 gas 消耗
    function testGas_MultiplyOptimized() public {
        arithmeticOptimized.multiply(10, 20);
        arithmeticOptimized.multiplyByPowerOfTwo(10, 2);
    }

    // 测试普通除法的 gas 消耗
    function testGas_Divide() public {
        arithmetic.divide(100, 5);
    }

    // 测试优化版除法的 gas 消耗
    function testGas_DivideOptimized() public {
        arithmeticOptimized.divide(100, 5);
        arithmeticOptimized.divideByPowerOfTwo(100, 2);
    }
}