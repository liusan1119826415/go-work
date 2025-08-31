
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//枚举
enum Status {
    Active, Inactive
}


//整型

contract StackTypes {
    function integerTypes() public pure{
        uint256 i =1;
        uint8 b = 2;

        uint256 c = 8899;

        uint8 d = 8;
    }

    function booleanTypes() public pure{
        bool isTrue = true;

        bool isFalse = false;
    }

    function addressTypes() public pure{
        bytes1 b1 = 0x12;

        bytes32 b32 = 0x877...;


    }

    //枚举

    function enumTypes() public pure {
        Status status = Status.Active; 
    }

    //数组

    function ArrayTypes() public pure{
        //命名数组
        uint256[] public arrayVal;
        
        address[] public VoteAddress;

        //命名mapping

        mapping(address=>uint) public VoteNum;

    }



}


contract ArrayExample {
    uint[] public storageArray; //存储在链上

    function example() public{
        uint[]memory memoryArray = new uint[](3);
    }

    //结构体

    struct Person {
        string name;
        uint age;
    }

    Person public memoryPerson;

    function personExample() public {
           Person memory memoryPerson = Person("张三",28);

    }


    //for 循环

    for(i=0;i<20;i++){

    }

    while (i<20) {
        sum += i;
        i++;
    }

    do{
      i++;
    }while(i<20);


}


//练习斐波那契数列第 n 项

function fibonacci(uint n) public pure returns (uint){
    if (n == 0) return 0;
    if (n == 1) return 1;

    a = 0;
    b = 1;
    uint c;

    for (uint i = 2; i<n;i++){
        c = a+b;

        a = b;
        b = c;
    }
    return b;
}

//批量添加白名单

mapping(address=>bool) public whileUser;

function appendWhileAddress(address[] calldata users) external {
      uint length = users.length;
      for( uint i = 0; i<length;i++){
        whileUser[users[i]] = true;
      }
}

//检查数据是否有重复

function hasDuplicate(uint[] memory arr) public pure returns (bool){
          uint length = arr.length;

          for(uint i = 0; i<length;i++){

            for(uint j = i+1;j<length;j++){
                if(arr[i] == arr[j]){
                    return true;
                }
            }
          }

          return false;
}

//计算偶数之和

function sunEvum(uint[] calldata arr) public pure returns (uint sum){
        uint len = arr.length;
        for(uint i =0;i<len;){
            uint num = arr[i];
            if(num % 2 == 0){
                 sum +=num;
            }
            unchecked {
                i++;
            }
        }
} 


//支付合约

contract Payment {
    function pay()public payable{}

    function getBalance() public view returns (uint){
        return address(this).balance;
    }
}

//触发自定义错误

error InsufficientBalance(uint256 available,uint256 required);

function withdraw(uint256 amount) public {
    if (amount >balances[msg.sender]){
        revert InsufficientBalance(balances[msg.sender],amount);
    }
}

try externalCOntract.someFunction(arg1,arg2) returns(uint256 resuult){

}catch Error(string memory reason) {
    
}catch Panic(uint errorCode){

}catch(bytes memory lowLevelData){

}

//声明一个地址变量

address public myAddress;

//获取当前调用者地址
address public caller = msg.sender;


function functionName() public payable(){

}

contract MyContract{
    event Received(address sender,uint amount);

    receive() external payable {
        emit Received(msg.sender,msg.value);
    }

    event FallbackCalled(address sender,uint amount,bytes data);


    fallback() external payable {
        emit FallbackCalled(msg.sender,msg.value,msg.data);
    }
}

//合约向外转账方式

payable(msg.sender).transfer(1 ether);

bool success = payable(msg.sender).send(1 ether);
require(success,"Send failed");

//call 推荐

(bool success, ) = payable(msg.sender).call{value:1 ether}("");

(bool success,) = payable(msg.sender).call{value:1 ether}("");

//收款和提款合约


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Vault {
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    receive() external payable{}


    function withdraw() external {
        require(msg.sender == owner,"Not owner");

        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success,"Withdraw failed");
    }


    function getBalance()external view returns (uint){
        return address(this).balance;
    }
}



