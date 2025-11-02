//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VulnerableToken is ERC20, ReentrancyGuard{
    //兑换比例1000代币 = 1ETH
    uint256 public constant EXCHANGE_RATE = 1000;
    
    // 用于模拟有漏洞的状态，绕过 ERC20 的保护
    mapping(address => uint256) public vulnerableBalances;

    constructor() ERC20("VulnerableToken", "VUL"){
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    //接收ETH函数
    receive() external payable{}

    // 🔴 有漏洞的版本 - 不使用 ReentrancyGuard，先更新状态再转账
    function burnForETHVulnerable(uint256 amount) external{
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // 🔴 漏洞：先销毁代币（更新状态）
        _burn(msg.sender, amount);

        //计算应得eth
        uint256 ethAmount = amount / EXCHANGE_RATE;

        // 🔴 危险！在状态更新后转账，可能被重入攻击
        // 攻击者可以在 receive() 中再次调用此函数
        (bool success,) = payable(msg.sender).call{value:ethAmount}("");
        require(success, "eth transfer failed");
    }

    // 🟢 安全的版本 - 使用 ReentrancyGuard
    function burnForETHSafe(uint256 amount) external nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // 销毁代币
        _burn(msg.sender, amount);
        
        // 计算应得 ETH
        uint256 ethAmount = amount / EXCHANGE_RATE;
        
        // 🟢 安全！nonReentrant 修饰符防止重入
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "eth transfer failed");
    }

    function deposit() external payable {}

    //查看合约eth余额
    function getEthBalance() external view returns(uint256){
        return address(this).balance;
    }
    
}