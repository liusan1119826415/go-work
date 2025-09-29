// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./Auction.sol";
import "./IAuctionFactor.sol";
import "./ICrossChainAuction.sol";

// CCIP 导入
import "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

/**
 * @title 跨链拍卖工厂合约
 * @dev 支持多链NFT拍卖，使用Chainlink CCIP进行跨链通信
 */
contract AuctionFactor is IAuctionFactor, ICrossChainAuction, CCIPReceiver {
    using Client for Client.EVM2AnyMessage;
    
    // ============ 状态变量 ============
    
    // 拍卖管理
    address[] public auctions;
    address public immutable proxyAdmin;
    address public implementation;
    mapping(uint256 => address) public auctionMap;
    mapping(address => uint256[]) public userAuctions;
    mapping(address => AggregatorV3Interface) public priceFeeds; // 价格预言机
    
    // 跨链拍卖状态
    mapping(uint256 => uint64) public auctionTargetChainId; // auctionId => 目标链ID
    mapping(uint256 => bool) public auctionSettled;         // 拍卖是否已结算
    mapping(bytes32 => bool) public processedMessages;      // 已处理的消息ID
    
    // CCIP配置
    uint64 public currentChainId;                           // 当前链ID
    mapping(uint64 => address) public remoteAuctionFactors; // 远程链上的拍卖工厂地址
    
    // 消息计数器
    uint256 public messageCounter;


    // 拍卖数据结构
    struct AuctionData {
        address seller;
        uint256 duration;
        uint256 minBid;
        uint256 highestBid;
        address highestBidder;
        bool ended;
        uint256 startTime;
        uint256 endTime;
        address nftContract;
        uint256 tokenId;
        address tokenAddress;
    }
    
    // ============ 事件 ============
    
    event AuctionCreated(address indexed auctionAddress, uint256 indexed auctionId, address indexed creator);
    event PriceFeedSet(address indexed token, address indexed priceFeed);
    event RemoteFactorSet(uint64 indexed chainId, address indexed factorAddress);
    
    // ============ 修饰器 ============
    
    modifier onlyAuctionOwner(uint256 auctionId) {
        require(auctionId < auctions.length, "Invalid auction ID");
        address auctionAddress = auctionMap[auctionId];
        AuctionData memory auctionInfo = _getAuctionData(auctionAddress, auctionId);
        require(auctionInfo.seller == msg.sender, "Not auction owner");
        _;
    }
    
    modifier auctionActive(uint256 auctionId) {
        require(auctionId < auctions.length, "Invalid auction ID");
        address auctionAddress = auctionMap[auctionId];
        AuctionData memory auctionInfo = _getAuctionData(auctionAddress, auctionId);
        require(!auctionInfo.ended, "Auction already ended");
        require(block.timestamp < auctionInfo.endTime, "Auction expired");
        _;
    }
    
    // modifier onlyProxyAdmin() {
    //     require(msg.sender == proxyAdmin, "Only proxy admin");
    //     _;
    // }
    
    // ============ 构造函数 ============
    
    constructor(
        address _implementation,
        address _proxyAdmin,
        address _router,
        uint64 _chainId
    ) CCIPReceiver(_router) {
        implementation = _implementation;

        console.log("implementation Address:", implementation);
        proxyAdmin = _proxyAdmin;
        console.log("Proxy Admin Address:", implementation);
        currentChainId = _chainId;
        

    }
    
    // ============ CCIP消息接收（正确实现） ============
    
    /**
     * @dev 重写_ccipReceive函数来处理跨链消息
     */
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        // 验证发送者（CCIPReceiver已经验证了onlyRouter）
        bytes32 messageId = message.messageId;
        require(!processedMessages[messageId], "Message already processed");
        
        // 解码消息
        CrossChainMessage memory receivedMessage = abi.decode(message.data, (CrossChainMessage));
        
        // 验证消息有效性
        require(verifyCrossChainMessage(receivedMessage), "Invalid cross-chain message");
        require(receivedMessage.targetChainId == currentChainId, "Invalid target chain");
        
        // 标记消息已处理
        processedMessages[messageId] = true;
        
        // 根据消息类型处理
        _handleCrossChainMessage(receivedMessage);
        
        emit CrossChainMessageReceived(
            receivedMessage.messageId,
            receivedMessage.sourceChainId,
            receivedMessage.messageType
        );
    }
    
    // ============ 实现IAuctionFactor接口函数 ============
    
    function getPrice(address tokenAddress) external view returns (int256) {
        AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
        require(address(priceFeed) != address(0), "Price feed not set");
        
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
    
    function setPriceFeed(address tokenAddress, address priceFeedAddress) external  {
        priceFeeds[tokenAddress] = AggregatorV3Interface(priceFeedAddress);
        emit PriceFeedSet(tokenAddress, priceFeedAddress);
    }
    
    function endAuction(uint256 auctionId) external  {
        address auctionAddress = auctionMap[auctionId];
        require(auctionAddress != address(0), "Auction does not exist");
        Auction(auctionAddress).endAuction(auctionId);
    }
    
    // ============ 实现ICrossChainAuction接口函数 ============
    
    function sendCrossChainMessage(
        CrossChainMessage memory message,
        uint64 targetChainId
    ) external  {
        // 只有合约本身或授权地址可以调用
        require(msg.sender == address(this) || remoteAuctionFactors[targetChainId] != address(0), "Unauthorized");
        _sendCrossChainMessage(message, targetChainId);
    }
    
    // ============ 拍卖管理函数 ============
    
    function createAuction(
        uint256 _duration,
        uint256 _minBid,
        address _nftContract,
        uint256 _tokenId
    ) public   returns (address) {
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(
            IERC721(_nftContract).getApproved(_tokenId) == address(this) ||
            IERC721(_nftContract).isApprovedForAll(msg.sender, address(this)),
            "Factory not approved"
        );
        
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementation,
            proxyAdmin,
            ""
        );
        
        address auctionAddress = address(proxy);
        
        Auction(auctionAddress).initialize();
        Auction(auctionAddress).setFactory(address(this));
        // 3. 先转移NFT到拍卖合约
        IERC721(_nftContract).safeTransferFrom(msg.sender, auctionAddress, _tokenId);
    
    // 4. 然后创建拍卖
        Auction(auctionAddress).createAuction(_duration, _minBid, _nftContract, _tokenId);
        
        
        
        auctions.push(auctionAddress);
        uint256 auctionId = auctions.length - 1;
        auctionMap[auctionId] = auctionAddress;
        userAuctions[msg.sender].push(auctionId);
        
        emit AuctionCreated(auctionAddress, auctionId, msg.sender);
        return auctionAddress;
    }
    
    function createCrossChainAuction(
        uint256 duration,
        uint256 minBid,
        address nftContract,
        uint256 tokenId,
        uint64 targetChainId
    ) external override  {
        console.log("1111");
        require(targetChainId != currentChainId, "Target chain cannot be current chain");
        console.log("2222");
        require(remoteAuctionFactors[targetChainId] != address(0), "Remote factor not set");
  
        address auctionAddress = createAuction(duration, minBid, nftContract, tokenId);
        console.log("555", auctionAddress);
        uint256 auctionId = auctions.length - 1;
        auctionTargetChainId[auctionId] = targetChainId;
        console.log("666:", auctionId);
        uint256 messageId = messageCounter++;
        console.log("777:", messageId);
        CrossChainMessage memory message = CrossChainMessage({
            messageId: messageId,
            auctionId: auctionId,
            sender: msg.sender,
            sourceChainId: currentChainId,
            targetChainId: targetChainId,
            messageType: MessageType.AUCTION_CREATED,
            value: minBid,
            tokenAddress: address(0),
            nftContract: nftContract,
            nftTokenId: tokenId,
            timestamp: block.timestamp,
            signature: "",
            extraData: abi.encode(auctionAddress, duration)
        });
        

        _sendCrossChainMessage(message, targetChainId);
        
        emit CrossChainAuctionCreated(auctionId, nftContract, tokenId, currentChainId, targetChainId);
    }
    
    // ============ 出价函数 ============
    
    function placeBid(
        uint256 auctionId,
        uint256 amount,
        address tokenAddress
    ) external payable   auctionActive(auctionId) {
        address auctionAddress = auctionMap[auctionId];
        require(auctionAddress != address(0), "Auction does not exist");
        if (tokenAddress == address(0)) {
            require(msg.value == amount, "ETH value must match amount");
        }
        
        if (tokenAddress == address(0)) {
            Auction(auctionAddress).placeBid{value: msg.value}(
                auctionId, amount, tokenAddress, msg.sender
            );
        } else {
            Auction(auctionAddress).placeBid(
                auctionId, amount, tokenAddress, msg.sender
            );
            // ERC20在校验成功后再转入，避免失败时资金先被锁
            IERC20(tokenAddress).transferFrom(msg.sender, auctionAddress, amount);
        }
    }
    
    function placeCrossChainBid(
        uint256 auctionId,
        uint256 amount,
        address tokenAddress,
        uint64 sourceChainId,
        bytes calldata signature
    ) external payable override  auctionActive(auctionId) {
        address auctionAddress = auctionMap[auctionId];
        require(auctionAddress != address(0), "Auction does not exist");
        require(auctionTargetChainId[auctionId] == sourceChainId, "Invalid source chain");
        if (tokenAddress == address(0)) {
            require(msg.value == amount, "ETH value must match amount");
        }

        uint256 messageId = messageCounter++;
        CrossChainMessage memory message = CrossChainMessage({
            messageId: messageId,
            auctionId: auctionId,
            sender: msg.sender,
            sourceChainId: sourceChainId,
            targetChainId: currentChainId,
            messageType: MessageType.BID_PLACED,
            value: amount,
            tokenAddress: tokenAddress,
            nftContract: address(0),
            nftTokenId: 0,
            timestamp: block.timestamp,
            signature: signature,
            extraData: ""
        });
        
        require(verifyCrossChainMessage(message), "Invalid cross-chain message");
        
        if (tokenAddress == address(0)) {
            Auction(auctionAddress).placeBid{value: msg.value}(
                auctionId, amount, tokenAddress, msg.sender
            );
        } else {
            Auction(auctionAddress).placeBid(
                auctionId, amount, tokenAddress, msg.sender
            );
        }
        
        message.messageType = MessageType.BID_PLACED;
        message.targetChainId = sourceChainId;
        _sendCrossChainMessage(message, sourceChainId);
        
        emit CrossChainBidPlaced(auctionId, msg.sender, amount, tokenAddress, sourceChainId);
    }
    
    // ============ 拍卖结算函数 ============
    
    function settleCrossChainAuction(
        uint256 auctionId,
        uint64 sourceChainId,
        bytes calldata signature
    ) external override  onlyAuctionOwner(auctionId) {
        require(!auctionSettled[auctionId], "Auction already settled");
        
        address auctionAddress = auctionMap[auctionId];
        AuctionData memory auctionInfo = _getAuctionData(auctionAddress, auctionId);
        
        require(!auctionInfo.ended, "Auction already ended");
        require(block.timestamp >= auctionInfo.endTime, "Auction not yet ended");
        
        uint256 messageId = messageCounter++;
        CrossChainMessage memory message = CrossChainMessage({
            messageId: messageId,
            auctionId: auctionId,
            sender: msg.sender,
            sourceChainId: currentChainId,
            targetChainId: sourceChainId,
            messageType: MessageType.AUCTION_ENDED,
            value: auctionInfo.highestBid,
            tokenAddress: auctionInfo.tokenAddress,
            nftContract: auctionInfo.nftContract,
            nftTokenId: auctionInfo.tokenId,
            timestamp: block.timestamp,
            signature: signature,
            extraData: abi.encode(auctionInfo.highestBidder)
        });
        
        require(verifyCrossChainMessage(message), "Invalid cross-chain message");
        
        Auction(auctionAddress).endAuction(auctionId);
        auctionSettled[auctionId] = true;
        
        if (sourceChainId != currentChainId) {
            _sendCrossChainNFT(message, sourceChainId);
        }
        
        _sendCrossChainMessage(message, sourceChainId);
        
        emit CrossChainAuctionEnded(auctionId, auctionInfo.highestBidder, auctionInfo.highestBid, sourceChainId);
    }
    
    // ============ 跨链消息处理 ============
    
    function _handleCrossChainMessage(CrossChainMessage memory message) internal {
        if (message.messageType == MessageType.AUCTION_CREATED) {
            _handleAuctionCreated(message);
        } else if (message.messageType == MessageType.BID_PLACED) {
            _handleBidPlaced(message);
        } else if (message.messageType == MessageType.AUCTION_ENDED) {
            _handleAuctionEnded(message);
        } else if (message.messageType == MessageType.NFT_TRANSFER) {
            _handleNFTTransfer(message);
        }
    }
    
    function _handleAuctionCreated(CrossChainMessage memory message) internal {
        emit CrossChainAuctionCreated(
            message.auctionId,
            message.nftContract,
            message.nftTokenId,
            message.sourceChainId,
            message.targetChainId
        );
    }
    
    function _handleBidPlaced(CrossChainMessage memory message) internal {
        emit CrossChainBidPlaced(
            message.auctionId,
            message.sender,
            message.value,
            message.tokenAddress,
            message.sourceChainId
        );
    }
    
    function _handleAuctionEnded(CrossChainMessage memory message) internal {
        address winner = abi.decode(message.extraData, (address));
        emit CrossChainAuctionEnded(
            message.auctionId,
            winner,
            message.value,
            message.sourceChainId
        );
    }
    
    function _handleNFTTransfer(CrossChainMessage memory message) internal {
        // 处理跨链NFT接收
    }
    
    // ============ 工具函数 ============
    
    function _sendCrossChainMessage(
        CrossChainMessage memory message,
        uint64 targetChainId
    ) internal returns (bytes32) {
        require(remoteAuctionFactors[targetChainId] != address(0), "Remote factor not set");
        
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(remoteAuctionFactors[targetChainId]),
            data: abi.encode(message),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})),
            feeToken: address(0)
        });
        address routeAddress = getRouter();
        uint256 fee = IRouterClient(routeAddress).getFee(targetChainId, evm2AnyMessage);
        
        bytes32 messageId = IRouterClient(routeAddress).ccipSend{value: fee}(
            targetChainId,
            evm2AnyMessage
        );
        
        emit CrossChainMessageSent(message.messageId, targetChainId, message.messageType);
        return messageId;
    }
    
    function _sendCrossChainNFT(
        CrossChainMessage memory message,
        uint64 targetChainId
    ) internal {
        message.messageType = MessageType.NFT_TRANSFER;
        _sendCrossChainMessage(message, targetChainId);
    }
    
    function verifyCrossChainMessage(
        CrossChainMessage memory message
    ) public view override returns (bool) {
        if (message.timestamp <= block.timestamp - 1 hours) return false;
        if (message.sourceChainId == 0 || message.targetChainId == 0) return false;
        return true;
    }
    
    function _getAuctionData(
        address auctionAddress,
        uint256 auctionId
    ) internal view returns (AuctionData memory) {
        (
            address seller,
            uint256 duration,
            uint256 minBid,
            uint256 highestBid,
            address highestBidder,
            bool ended,
            uint256 startTime,
            uint256 endTime,
            address nftContract,
            uint256 tokenId,
            address tokenAddress
        ) = Auction(auctionAddress).getAuctionItem(auctionId);
        
        return AuctionData(
            seller, duration, minBid, highestBid, highestBidder,
            ended, startTime, endTime, nftContract, tokenId, tokenAddress
        );
    }
    
    function setRemoteAuctionFactor(uint64 chainId, address factorAddress) external  {
        remoteAuctionFactors[chainId] = factorAddress;
        emit RemoteFactorSet(chainId, factorAddress);
    }
    
    function upgradeAuctionImplementation(address newImplementation) external  {
        implementation = newImplementation;
    }
    
    function getAuctions() external view  returns (address[] memory) {
        return auctions;
    }
    
    function getUserAuctions(address user) external view  returns (uint256[] memory) {
        return userAuctions[user];
    }
    
    function getAuctionCount() external view  returns (uint256) {
        return auctions.length;
    }
    
    receive() external payable {}
}