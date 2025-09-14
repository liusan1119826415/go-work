//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNft is ERC721URIStorage, Ownable{

    uint256 private _tokenIds;

    constructor() ERC721("MyNft","MNFT") Ownable(msg.sender){}

    ///@notice筹造一个NFT， 关联元数据链接
    ///@param recipient 接收NFT 的地址
    ///@param tokenURI 关联的元数据链接

    function mintNFT(address recipient, string memory tokenURI) public onlyOwner returns(uint256){
        _tokenIds++;
        uint256 newItemId = _tokenIds;

        _mint(recipient,newItemId);

        _setTokenURI(newItemId,tokenURI);
        return newItemId;

    }

}