//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract S3NFT is ERC721Enumerable {
    string private _BASE_URI;

    uint256 private _nextTokenId = 0;
    uint256 public immutable MAX_SUPPLY;

    constructor() ERC721("S3NFT", "S3NFT") {
        _BASE_URI = "https://s3nft.com/api/token/";
        MAX_SUPPLY = 10000;
    }

    function _baseURI() internal view override returns (string memory) {
        return _BASE_URI;
    }

    function freeMint(uint256 amount) external {
        require(amount <= 5, "You call mint up to 5 tokens at once");
        uint256 nextTokenId = _nextTokenId;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, nextTokenId);
            nextTokenId++;
        }

        _nextTokenId = nextTokenId;
        require(_nextTokenId <= MAX_SUPPLY, "All tokens have been minted");
    }
}