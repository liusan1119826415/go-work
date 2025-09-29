// contracts/mocks/MockCCIPRouter.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract MockCCIPRouter is IRouterClient {
    event MessageSent(bytes32 indexed messageId, uint64 indexed destinationChainId, address indexed receiver);
    
    mapping(uint64 => bool) public supportedChains;
    uint256 public mockFee = 0.01 ether;
    
    constructor() {
        supportedChains[1] = true;
        supportedChains[2] = true;
    }
    
    function getFee(uint64 destinationChainId, Client.EVM2AnyMessage memory message) 
        external 
        view 
        returns (uint256 fee) 
    {
        require(supportedChains[destinationChainId], "Unsupported chain");
        return mockFee;
    }
    
    function ccipSend(uint64 destinationChainId, Client.EVM2AnyMessage memory message)
        external
        payable
        returns (bytes32)
    {
        require(supportedChains[destinationChainId], "Unsupported chain");
        require(msg.value >= mockFee, "Insufficient fee");
        
        bytes32 messageId = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        emit MessageSent(messageId, destinationChainId, abi.decode(message.receiver, (address)));
        
        return messageId;
    }
    
    // 实现其他必要接口函数
    function getRouter() external view returns (address) {
        return address(this);
    }
    
    function isChainSupported(uint64 chainId) external view returns (bool) {
        return supportedChains[chainId];
    }
    
    function getSupportedTokens(uint64 chainId) external view returns (address[] memory) {
        return new address[](0);
    }
}