//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./S3NFT.sol";

contract NFTFactory is Ownable(msg.sender) {
    mapping(address => bool) public regesiteredNFTs;

    event NFTCreated(address nftCA);
    event NFTRegesitered(address nftCA);

    function deployNFT() external returns (address) {
        S3NFT nft = new S3NFT();
        emit NFTCreated(address(nft));
        return address(nft);
    }

    function regesiterNFT(address nftCA) external onlyOwner {
        require(!regesiteredNFTs[nftCA], "NFT already regesitered");
        regesiteredNFTs[nftCA] = true;
        emit NFTRegesitered(nftCA);
    }
}

