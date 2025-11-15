// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Arithmetic} from "../src/Arithmetic.sol";

contract ArithmeticTest is Test {
    Arithmetic public arithmetic;

    function setUp() public {
        arithmetic = new Arithmetic();
    }

    function testAdd() public view {
        assertEq(arithmetic.add(1, 2), 3);
    }

    function testSubtract() public view {
        assertEq(arithmetic.subtract(5, 3), 2);
    }

    function testMultiply() public view {
        assertEq(arithmetic.multiply(2, 3), 6);
    }

    function testDivide() public view {
        assertEq(arithmetic.divide(6, 3), 2);
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