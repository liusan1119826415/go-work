//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyERC20 {

    string public name = "MyToken";

    string public symbol = "MTK";

    uint8 public decimals = 18;

    uint256 public totalSupply;

    //账户余额
    mapping(address => uint256) private balanceOf;
    //授权额度 allownance[owner][spender] = amount
    mapping(address => mapping(address=>uint256)) private _allownance;


    //事件
    event Transfer(address indexed from, address indexed to,uint256 value);
    
    event Approval(address indexed owner,address indexed spender, uint256 value);
    //部署者
    address public owner; 

    constructor(){
        owner = msg.sender;
    }

    //查询账户余额

    function bananceOf(address account) external view returns(uint256){
        return balanceOf[account];
    }

    //转账

    function transfer(address to,uint256 amount) external returns(bool){
        require(to != address(0),"to is zero address");
        require(balanceOf[msg.sender] >= amount,"balance is not enough");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;

    }
    //授权spender 可以代扣 amount
    function approval(address spender,uint256 amount) external returns(bool){
        require(spender != address(0),"spender is zero address");
        _allownance[msg.sender][spender]= amount;
         emit Approval(msg.sender, spender, amount);
         return true;
    }

    //代扣转账

    function transferFrom(address from,address to,uint256 amount) public returns (bool){
        require(to != address(0),"to is zero address");
        require(balanceOf[from] >= amount,"balance is not enough");
        require(_allownance[from][msg.sender]>=amount,"allownance is not enough");
        balanceOf[from] -= amount;
        balanceOf[to]+=amount;
        _allownance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);

        return true;
    }

    //只有owner 能增发代币
    function mint(address to,uint256 amount) external {
        require(msg.sender == owner ,"only owner can mint");

        require(to != address(0),"to is zero address");

        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    //查询授权额度

    function allownance(address accountOwner,address spender) external view returns(uint256){
        return _allownance[accountOwner][spender];
    }






}