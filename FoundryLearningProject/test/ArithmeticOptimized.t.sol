// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ArithmeticOptimized} from "../src/ArithmeticOptimized.sol";

contract ArithmeticOptimizedTest is Test {
    ArithmeticOptimized public arithmetic;

    function setUp() public {
        arithmetic = new ArithmeticOptimized();
    }

    function testAddUnchecked() public view {
        assertEq(arithmetic.addUnchecked(1, 2), 3);
    }

    function testAdd() public view {
        assertEq(arithmetic.add(1, 2), 3);
    }

    function testSubtractOptimized() public view {
        assertEq(arithmetic.subtractOptimized(5, 3), 2);
    }

    function testSubtract() public view {
        assertEq(arithmetic.subtract(5, 3), 2);
    }

    function testMultiplyByPowerOfTwo() public view {
        assertEq(arithmetic.multiplyByPowerOfTwo(3, 2), 12);
    }

    function testMultiply() public view {
        assertEq(arithmetic.multiply(2, 3), 6);
    }

    function testDivideByPowerOfTwo() public view {
        assertEq(arithmetic.divideByPowerOfTwo(12, 2), 3);
    }

    function testDivide() public view {
        assertEq(arithmetic.divide(6, 3), 2);
    }

    function test_RevertWhen_SubtractOptimizedUnderflow() public {
        vm.expectRevert();
        arithmetic.subtractOptimized(1, 3);
    }

    function test_RevertWhen_SubtractUnderflow() public {
        vm.expectRevert();
        arithmetic.subtract(1, 3);
    }

    function test_RevertWhen_DivideByZero() public {
        vm.expectRevert();
        arithmetic.divide(1, 0);
    }
}