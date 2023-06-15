// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {NotAllowed, NotEnoughFunds} from "./Errors.sol";

contract NFTMarketplace is IERC721Receiver, ReentrancyGuard {
    struct ItemInfo {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => ItemInfo)) public itemsForSale;
    mapping(address => uint256) public amountToClaim;

    event ItemListed(
        address seller,
        address nftAddress,
        uint256 tokenId,
        uint256 price
    );
    event ItemBought(
        address buyer,
        address nftAddress,
        uint256 tokenId,
        uint256 price
    );
    event ItemUnlisted(address seller, address nftAddress, uint256 tokenId);
    event FundsClaimed(address seller, uint256 amount);

    constructor() {}

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        IERC721(nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        itemsForSale[nftAddress][tokenId] = ItemInfo({
            seller: msg.sender,
            price: price
        });

        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function unlistItem(
        address nftAddress,
        uint256 tokenId
    ) external nonReentrant {
        if (itemsForSale[nftAddress][tokenId].seller != msg.sender) {
            revert NotAllowed();
        }

        delete itemsForSale[nftAddress][tokenId];
        IERC721(nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        emit ItemUnlisted(msg.sender, nftAddress, tokenId);
    }

    function buyItem(
        address nftAddress,
        uint256 tokenId
    ) external payable nonReentrant {
        if (msg.value < itemsForSale[nftAddress][tokenId].price) {
            revert NotEnoughFunds();
        }

        amountToClaim[itemsForSale[nftAddress][tokenId].seller] += msg.value;
        delete itemsForSale[nftAddress][tokenId];

        IERC721(nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        emit ItemBought(msg.sender, nftAddress, tokenId, msg.value);
    }

    function claimFunds() external nonReentrant {
        payable(msg.sender).transfer(amountToClaim[msg.sender]);
        amountToClaim[msg.sender] = 0;

        emit FundsClaimed(msg.sender, amountToClaim[msg.sender]);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getItemForSale(
        address nftAddress,
        uint256 tokenId
    ) external view returns (ItemInfo memory) {
        return itemsForSale[nftAddress][tokenId];
    }
}
