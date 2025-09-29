// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICrossChainAuction.sol";

contract MyNftERC721 is ERC721Enumerable, Ownable {
    string private _baseTokenURI;
    address public crossChainAuction;
    
    // 跨链状态跟踪
    mapping(uint256 => bool) public crossChainTransferred;
    mapping(uint256 => uint256) public tokenTargetChain; // tokenId => targetChainId
    mapping(bytes32 => bool) public processedCrossChainMessages;

    event CrossChainTransferInitiated(
        uint256 indexed tokenId,
        uint256 indexed targetChainId,
        address indexed sender
    );
    
    event CrossChainTransferCompleted(
        uint256 indexed tokenId,
        address indexed recipient
    );

    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    function setCrossChainAuction(address _crossChainAuction) external onlyOwner {
        crossChainAuction = _crossChainAuction;
    }

    function mintNFT(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function mintNFTWithURI(address to, uint256 tokenId, string memory uri) external onlyOwner {
        _mint(to, tokenId);
        // 如果有需要，可以存储tokenURI
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
       // require(ERC721._exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_baseTokenURI, toString(tokenId)));
    }

    function setBaseTokenURI(string memory newBaseTokenURI) external onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    /**
     * @dev 数字转字符串辅助函数
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


}