//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract  AlgorithmProblems {
    


    // 使用状态变量来存储罗马数字映射
    mapping(bytes1 => uint256) private romanMap;
    
    constructor() {
        // 在构造函数中初始化罗马数字映射
        romanMap[bytes1('I')] = 1;
        romanMap[bytes1('V')] = 5;
        romanMap[bytes1('X')] = 10;
        romanMap[bytes1('L')] = 50;
        romanMap[bytes1('C')] = 100;
        romanMap[bytes1('D')] = 500;
        romanMap[bytes1('M')] = 1000;
    }
    //反转字符

    function reverseString(string memory str) public pure returns(string memory){

        //pure 函数不读取也不修改合约状态
        bytes memory strBytes = bytes(str);
        uint length = strBytes.length;

        bytes memory reversed = new bytes(length);

        for(uint i=0;i<length;i++){
            reversed[i] = strBytes[length-1-i];

        }

        return string(reversed);
    }

    //整数转罗马数字

    function intToRoman(uint256 num) public pure returns (string memory){
        require(num>0 && num <4000,"Number must be between 1 and 3999");
        string[10][4] memory romanNumerals = [
            // 定义一个4x10的二维数组，存储罗马数字字符
            ["", "M", "MM", "MMM", "", "", "", "", "", ""],        // 千位：0-9
            ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"], // 百位：0-9
            ["", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"], // 十位：0-9
            ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]  // 个位：0-9
        ];
        

        uint256[] memory digits = new uint256[](4);

        digits[0] = num / 1000;        // 提取千位数
        digits[1] = (num % 1000) / 100; // 提取百位数：先取模1000去掉千位，再除以100
        digits[2] = (num % 100) / 10;   // 提取十位数：先取模100去掉百位，再除以10
        digits[3] = num % 10;           // 提取个位数：直接取模10

        string memory result;

        for(uint i=0;i<4;i++){
            result = string(abi.encodePacked(result,romanNumerals[i][digits[i]]));
        }
        return result;
    }

    // 罗马数字转整数
    function romanToInt(string memory s) public view returns (uint256) {
        bytes memory roman = bytes(s);
        uint256 length = roman.length;
        uint256 result = 0;
        
        for (uint256 i = 0; i < length; i++) {
            uint256 current = romanMap[roman[i]];
            uint256 next = (i < length - 1) ? romanMap[roman[i + 1]] : 0;
            
            if (current < next) {
                result += next - current;
                i++; // 跳过下一个字符
            } else {
                result += current;
            }
        }
        return result;
    }

    //合并两个有序数组
    function mergeSortArrays(uint[] memory array1,uint[] memory array2) public pure returns(uint[] memory){
                 
                 uint len1 = array1.length;
                 uint len2 = array2.length;

                 uint[] memory merged = new uint[](len1+len2);

                 uint i = 0;
                 uint j = 0;
                 uint k = 0;

                 while(i <len1 && j < len2){
                    if(array1[i] <=array2[j]){
                        merged[k] = array1[i];
                        i++;
                    }else{
                        merged[k] = array2[j];
                        j++;
                    }
                    k++;
                 }
                 while(i <len1){
                    merged[k] = array1[i];
                    i++;
                    k++;
                 }

                 while(j <len2){
                    merged[k] = array2[j];
                    j++;
                    k++;
                 }

                 return merged;
    }


    function binarySearch(uint[] memory arr, uint traget) public pure returns (int){

        uint left = 0;

        uint right = arr.length -1;
        //当左边界不大于右边界

        while(left <= right){
            uint mid = left + (right - left)/2;

            if (arr[mid] == traget){
                return int(mid);
            }

            if (arr[mid] < traget){
                //如果中间值小于目标值
                left = mid +1;
            }else{
                if(mid == 0) break;
                right = mid -1;
            }


        }

        return -1;
    }

}

