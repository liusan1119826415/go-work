// ICrossChainAuction.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICrossChainAuction {
    // 跨链拍卖消息结构
    struct CrossChainMessage {
        uint256 messageId;        // 消息ID
        uint256 auctionId;        // 拍卖ID
        address sender;           // 发送者
        uint64 sourceChainId;     // 源链ID (使用uint64匹配CCIP)
        uint64 targetChainId;     // 目标链ID
        MessageType messageType;  // 消息类型
        uint256 value;            // 金额
        address tokenAddress;     // 代币地址
        address nftContract;      // NFT合约地址
        uint256 nftTokenId;       // NFT Token ID
        uint256 timestamp;        // 时间戳
        bytes signature;          // 签名
        bytes extraData;          // 额外数据
    }

    // 消息类型枚举
    enum MessageType {
        AUCTION_CREATED,  // 拍卖创建
        BID_PLACED,       // 出价提交
        AUCTION_ENDED,    // 拍卖结束
        NFT_TRANSFER      // NFT转移
    }

    // 事件
    event CrossChainAuctionCreated(
        uint256 indexed auctionId,
        address indexed nftContract,
        uint256 indexed nftTokenId,
        uint64 sourceChainId,
        uint64 targetChainId
    );

    event CrossChainBidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 value,
        address tokenAddress,
        uint64 sourceChainId
    );

    event CrossChainAuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 value,
        uint64 sourceChainId
    );

    event CrossChainMessageSent(
        uint256 indexed messageId,
        uint64 indexed targetChainId,
        MessageType messageType
    );

    event CrossChainMessageReceived(
        uint256 indexed messageId,
        uint64 indexed sourceChainId,
        MessageType messageType
    );

    // 跨链拍卖创建
    function createCrossChainAuction(
        uint256 duration,
        uint256 minBid,
        address nftContract,
        uint256 tokenId,
        uint64 targetChainId
    ) external ;

    // 跨链出价
    function placeCrossChainBid(
        uint256 auctionId,
        uint256 amount,
        address tokenAddress,
        uint64 sourceChainId,
        bytes calldata signature
    ) external payable;

    // 跨链拍卖结算
    function settleCrossChainAuction(
        uint256 auctionId,
        uint64 sourceChainId,
        bytes calldata signature
    ) external;

    // 验证跨链消息
    function verifyCrossChainMessage(
        CrossChainMessage memory message
    ) external view returns (bool);

    // 处理接收到的跨链消息
    // function ccipReceive(
    //     bytes memory messageData
    // ) external;
}