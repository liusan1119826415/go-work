//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "./Auction.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./IAuctionFactor.sol";

contract AuctionFactor is IAuctionFactor {
    address[] public auctions;

    address public immutable proxyAdmin;

    address public implementation;

    mapping(uint256=>address) public auctionMap;

    mapping(address =>uint256[]) public userAuctions;

    mapping(address=> AggregatorV3Interface) public priceFeeds;

    event AuctionCreated(address indexed auctionAddress, uint256 indexed auctionId, address indexed creator);
    event PriceFeedSet(address indexed token, address indexed priceFeed);
    constructor(address _implementation, address _proxyAdmin) {
         implementation = _implementation;
        proxyAdmin = _proxyAdmin;
       

        Auction(implementation).initialize();
    }

    function createAuction(uint256 _duration, uint256 _minBid, address _nftContract, uint256 _tokenId) external returns (address) {

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
        Auction(auctionAddress).initialize(); // 确保初始化
        
        Auction(auctionAddress).setFactory(address(this));

    // 关键步骤：将NFT直接从卖家转移到拍卖合约
       IERC721(_nftContract).safeTransferFrom(msg.sender, auctionAddress, _tokenId);

        Auction(auctionAddress).createAuction(_duration, _minBid, _nftContract, _tokenId);

        auctions.push(auctionAddress);
        uint256 auctionId = auctions.length - 1;
        auctionMap[auctionId] = auctionAddress;
        userAuctions[msg.sender].push(auctionId);

        emit AuctionCreated(auctionAddress, auctionId, msg.sender); // 确保事件正确触发
        return auctionAddress;
    }



    function upgradeAuctionImplementation(address newImplementation) external {
        require(msg.sender == proxyAdmin, "Only proxy admin can upgrade");
    
        implementation = newImplementation;
    }
    
    function getAuctions() external view returns (address[] memory) {
        return auctions;
    }


    function getAuction(uint256 auctionId) external view returns (
        address seller,
        uint256 duration,
        uint256 minBid,
        uint256 highestBid,
        address highestBidder,
        bool ended,
        uint256 startTime,
        uint256 endTime,
        address NFTcontruct,
        uint256 tokenId,
        address tokenAddress
        ) {
        require(auctionId < auctions.length, "Invalid auction ID");
        address auctionAddress = auctionMap[auctionId];
      
        return Auction(auctionAddress).getAuctionItem(auctionId);
       }

    function getUserAuctions(address user) external view returns (uint256[] memory) {
        return userAuctions[user];
    }

    function getAuctionCount() external view returns (uint256) {
        return auctions.length;
    }

    function getAuctionMap(uint256 auctionId) external view returns (address) {
        return auctionMap[auctionId];
    }

    function placeBid(uint256 auctionId, uint256 amount, address tokenAddress) external payable {
        console.log("Placing bid on auction ID:", auctionId);
        address auctionAddress = auctionMap[auctionId];
        require(auctionAddress != address(0), "Auction does not exist");
        
        // 获取调用者（真正的出价者）
        address bidder = msg.sender;
        
        if (tokenAddress == address(0)) {
            // ETH出价 - 传递value和出价者地址
            Auction(auctionAddress).placeBid{value: msg.value}(
                auctionId, 
                amount, 
                tokenAddress,
                bidder
            );
        } else {
            // ERC20出价 - 只需要传递出价者地址
            Auction(auctionAddress).placeBid(
                auctionId, 
                amount, 
                tokenAddress,
                bidder
            );
        }
        
        
    }

    //结束拍卖
    function endAuction(uint256 auctionId) external {
        address auctionAddress = auctionMap[auctionId];
        require(auctionAddress != address(0), "Auction does not exist");

        Auction(auctionAddress).endAuction(auctionId);
    }


    // 设置价格预言机
    function setPriceFeed(address tokenAddress, address priceFeedAddress) external {
        priceFeeds[tokenAddress] = AggregatorV3Interface(priceFeedAddress);
        emit PriceFeedSet(tokenAddress, priceFeedAddress);
    }


    // 获取价格
    function getPrice(address tokenAddress) external view returns (int256) {
        AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
        require(address(priceFeed) != address(0), "Price feed not set");
        
        // 根据你的AggregatorV3实现返回价格
        // 如果是真实的Chainlink预言机，应该这样调用：
        // (, int256 price, , , ) = priceFeed.latestRoundData();
        // return price;
        
        // 如果是你的模拟预言机，直接调用相应方法
         (, int256 price, , , ) = priceFeed.latestRoundData();
            uint8 decimals = priceFeed.decimals();
            console.log("Token:", tokenAddress);
            console.log("Raw Price:", uint256(price));
            console.log("Decimals:", decimals);
        return price;
    }

}