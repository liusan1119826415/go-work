// 反转字符串 (Reverse String)
// 题目描述：反转一个字符串。输入 "abcde"，输出 "edcba"
//用 solidity 实现整数转罗马数字
//用 solidity 实现罗马数字转数整数
//合并两个有序数组 (Merge Sorted Array)
//题目描述：将两个有序数组合并为一个有序数组。

//二分查找 (Binary Search)
//题目描述：在一个有序数组中查找目标值。

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StringReverse {

    function reverse(string memory s) public pure returns(string memory){
        bytes memory str = bytes(s);

        uint256 len = str.length;
        for(uint i =0;i<len;i++){
            //交换str[i]和str[len-1-i]

            bytes1 temp = str[i];
            str[i] = str[len -1 -i];
            str[len -1 -i] = temp;
        }
        return string(str);
    }
 }
