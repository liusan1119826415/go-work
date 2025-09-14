//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract MyToken {


    string public name = "MyToken";

    string public symbol = "MKK";

    uint8 public decimals = 18;

    uint256 public totalSupply;
    // 账户余额
    mapping(address => uint256) private balances;
    
    // 授权余额
    mapping(address=>mapping(address=>uint256)) private allownances;



    // 事件
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    //部署者
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    //查询账户余额
    function balanaceOf(address account) external view returns(uint256){
        return balances[account];
    }

    //转账

    function transfer(address to, uint256 amount) external returns(bool){

        require(to != address(0),"to is zero address");

        require(balances[msg.sender]>=amount,"balance is not enough");
        balances[msg.sender] -= amount;
        balances[to]+=amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    //授权
    function approver(address spender, uint256 amount) external returns(bool){
        require(spender != address(0),"spender is zero address");
        allownances[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }

    //代扣转账

    function transferFrom(address from, address to , uint256 amount) public returns(bool){
        require(to != address(0),"to is zero address");
        require(allownances[from][msg.sender]>= amount,"allownance is not enough");
        require(balances[from]>= amount,"balance is not enough");

        balances[from] -= amount;
        allownances[from][msg.sender] -= amount;
        balances[to]  += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    //发行代币

    function mint(address to ,uint256 amount) external{
        require(to != address(0),"to is zero address");
        require(msg.sender == owner,"only owner can mint");

        totalSupply += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
        return true;
    }

    //查询授权余额

    function allownance(address accountOwner, address spender) external view returns(uint256){
        return allownances[accountOwner][spender];
    }

    //
    

}