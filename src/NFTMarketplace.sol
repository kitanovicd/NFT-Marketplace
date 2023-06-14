// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract NFTMarketplace {
    struct ItemInfo {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => ItemInfo)) public itemsForSale;

    constructor() {}

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        IERC721 nftContract = IERC721(nftAddress);
        nftContract.transferFrom(msg.sender, address(this), tokenId);
        itemsForSale[nftAddress][tokenId] = ItemInfo({
            seller: msg.sender,
            price: price
        });
    }
}
