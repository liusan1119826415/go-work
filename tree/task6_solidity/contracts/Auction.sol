//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "./IAuctionFactor.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
contract Auction is Initializable,UUPSUpgradeable,OwnableUpgradeable {
     //合约所有者

    
    //拍卖结构
    
    struct AuctionItem {
        address seller; //卖家 
        uint256 duration; //拍卖持续时间
        uint256 minBid; //最低出价
        uint256 highestBid; //最高出价
        address highestBidder; //最高出价者
        bool ended; //拍卖是否结束
        uint256 startTime; //拍卖开始时间
        uint256 endTime; //拍卖结束时间
        address NFTcontruct; //NFT合约地址
        uint256 tokenId; //NFT的tokenId
         // 参与竞价的资产类型 0x 地址表示eth，其他地址表示erc20
        // 0x0000000000000000000000000000000000000000 表示eth
        address tokenAddress;
  
    }
    address public factory; //工厂合约地址
    //下一个拍卖ID
    uint256 public nextAuctionId;

    //mapping(address=> AggregatorV3Interface) public priceFeeds;

    mapping(uint256 => AuctionItem) public auctions;
    function initialize() public initializer {
       
            __Ownable_init(msg.sender);
            __UUPSUpgradeable_init();
            nextAuctionId = 0;
     

    }

    function getTokenDecimals(address token) internal view returns (uint8) {
        if (token == address(0)) {
            return 18;
        }
        return IERC20Metadata(token).decimals();
    }
     //创建拍卖
    function createAuction(uint256 _duration,uint256 _startPrice, address _nftContract,uint256 _tokenId) public onlyFactory {
        require(_duration >0,"Duration must be greater than zero");
        require(_startPrice>0, "startPrice must be greater than zero");
        // 检查NFT是否已经在这个拍卖合约中
        require(IERC721(_nftContract).ownerOf(_tokenId) == address(this), "NFT not in this auction contract");

        //IERC721(_nftContract).safeTransferFrom(msg.sender,address(this),_tokenId);
        auctions[nextAuctionId] = AuctionItem({
            seller: msg.sender,
            duration: _duration,
            minBid: _startPrice,
            highestBid: 0,
            highestBidder: address(0),
            ended: false,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            NFTcontruct: _nftContract,
            tokenId: _tokenId,
            tokenAddress: address(0) //默认使用ETH
        });

        nextAuctionId++;

    }

    // 添加工厂权限修饰器
    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call");
        _;
    }

    function setFactory(address _factory) external {
        require(factory == address(0), "Factory already set");
        factory = _factory;
     }

    // function setPriceFeed(address tokenAddress,address _priceFeedAddress) public {
    //        priceFeeds[tokenAddress] = AggregatorV3Interface(_priceFeedAddress);
    // }

    // function getLastPrice(address tokenAddress) public view returns(uint256){
 
    //     AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
    //     (,int256  price,,,) = priceFeed.latestRoundData();
    //     return uint256(price);
    // }







   //参与拍卖 - 简化版本
        function placeBid(
            uint256 auctionId,
            uint256 amount,
            address _tokenAddress,
            address bidder // 添加出价者地址参数
        ) external payable onlyFactory { // 添加onlyFactory修饰器
            AuctionItem storage auction = auctions[auctionId];

            require(block.timestamp < auction.startTime + auction.duration, "Auction already ended");
            require(!auction.ended, "Auction already ended");



             // 从工厂合约获取价格
            int256 price = IAuctionFactor(factory).getPrice(_tokenAddress);
  
            require(price > 0, "Invalid price");
            uint256 payValue;
            if (_tokenAddress == address(0)) {
                amount = msg.value;
            }
            uint8 bidTokenDecimals = getTokenDecimals(_tokenAddress);
            payValue = (amount * uint256(price)) / (10 ** uint256(bidTokenDecimals));



            // 计算最低出价阈值：如果还没有出价，则以本次出价代币作为基准；
            // 一旦出现过出价，则继续以已锁定的代币类型作为基准
            // 最低出价始终以ETH为基准（测试中minBid按ETH设定）
            address minBidBaseToken = address(0);
            uint8 minBidBaseDecimals = 18;
            uint256 minBidPrice = (auction.minBid * uint256(IAuctionFactor(factory).getPrice(minBidBaseToken))) / (10 ** uint256(minBidBaseDecimals));

            uint8 highestTokenDecimals = getTokenDecimals(auction.tokenAddress);
            uint256 highestBidValue = (auction.highestBid * uint256(IAuctionFactor(factory).getPrice(auction.tokenAddress))) / (10 ** uint256(highestTokenDecimals));
            console.log("amount:", amount);
            console.log("PayValue:", payValue);
            console.log("MinBidValue:", minBidPrice);
            console.log("HighestBidValue:", highestBidValue);
            console.log("Price:", uint256(price));
            // 检查出价是否有效
            require(payValue >= minBidPrice, "Bid must be at least the minimum bid");
            require(payValue > highestBidValue || highestBidValue == 0, "There already is a higher bid");
            
            // ERC20 资金由工厂合约在本次调用成功后转入本拍卖合约
            // 退还前一个最高出价
            if (auction.highestBid > 0) {
                refundPreviousBidder(auction);
            }
           
            // 更新拍卖状态
            auction.highestBid = amount;
            auction.tokenAddress = _tokenAddress;
            auction.highestBidder = bidder; // 使用传入的bidder地址
        }

// 添加退款辅助函数
    function refundPreviousBidder(AuctionItem storage auction) internal {
        if (auction.tokenAddress == address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        } else {
            IERC20(auction.tokenAddress).transfer(auction.highestBidder, auction.highestBid);
        }
    }

    //结束拍卖
    function endAuction(uint256 auctionId) external {
        AuctionItem storage auction = auctions[auctionId];

        require(!auction.ended && auction.startTime + auction.duration <= block.timestamp, "Auction not yet ended");

        //转移NFT给最高出价者
        IERC721(auction.NFTcontruct).safeTransferFrom(address(this),auction.highestBidder,auction.tokenId);
        //转移资金给卖家
        if(auction.tokenAddress == address(0)){
            //使用eth 参与拍卖
            payable(auction.seller).transfer(auction.highestBid);
        }else{
            //使用erc20 参与拍卖
            IERC20(auction.tokenAddress).transfer(auction.seller,auction.highestBid);
        }
        auction.ended = true;
    }

    //使用UUPPR代理部署
    function _authorizeUpgrade(address) internal view override onlyOwner {}

    //onERC721Received 实现
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getAuction(uint256 _auctionId) external view returns (AuctionItem memory){
        return auctions[_auctionId];
    }

    function getAuctionItem(uint256 _auctionId) external view returns (
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
    AuctionItem storage auction = auctions[_auctionId];
    return (
        auction.seller,
        auction.duration,
        auction.minBid,
        auction.highestBid,
        auction.highestBidder,
        auction.ended,
        auction.startTime,
        auction.endTime,
        auction.NFTcontruct,
        auction.tokenId,
        auction.tokenAddress
    );
}
 }