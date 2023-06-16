// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {NotEnoughFunds, AuctionFinished, EthTransferFailed, AuctionNotFinished} from "./Errors.sol";

contract AuctionNFTMarketplace is IERC721Receiver, ReentrancyGuard, Ownable {
    struct AuctionInfo {
        address seller;
        address nftAddress;
        uint256 tokenId;
        address currentBidder;
        uint256 currentBidAmount;
        uint256 auctionEndTimestamp;
    }

    uint256 public constant AUCTION_FEE_PERCENTAGE = 5;
    uint256 public feeBalance;
    AuctionInfo[] public auctions;

    event AuctionStarted(
        address seller,
        address nftAddress,
        uint256 tokenId,
        uint256 startPrice,
        uint256 auctionDuration,
        uint256 auctionId
    );
    event AuctionBid(
        uint256 auctionId,
        address bidder,
        address nftAddress,
        uint256 tokenId,
        uint256 bidAmount
    );
    event AuctionClosed(
        uint256 auctionId,
        address seller,
        address winner,
        uint256 winningBid
    );

    constructor() {}

    function startAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 startPrice,
        uint256 auctionDuration
    ) external payable {
        uint256 feeAmount = (startPrice * AUCTION_FEE_PERCENTAGE) / 100;

        if (msg.value < feeAmount) {
            revert NotEnoughFunds();
        }

        feeBalance += feeAmount;

        IERC721(nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        auctions.push(
            AuctionInfo({
                seller: msg.sender,
                nftAddress: nftAddress,
                tokenId: tokenId,
                currentBidder: address(0x0),
                currentBidAmount: startPrice,
                auctionEndTimestamp: block.timestamp + auctionDuration
            })
        );

        emit AuctionStarted(
            msg.sender,
            nftAddress,
            tokenId,
            startPrice,
            auctionDuration,
            auctions.length - 1
        );
    }

    function bid(uint256 auctionId) external payable nonReentrant {
        AuctionInfo storage auction = auctions[auctionId];

        if (auction.auctionEndTimestamp < block.timestamp) {
            revert AuctionFinished();
        }
        if (msg.value > auction.currentBidAmount) {
            revert NotEnoughFunds();
        }

        if (auction.currentBidder != address(0x0)) {
            _safeTransferETH(auction.currentBidder, auction.currentBidAmount);
        }

        auction.currentBidder = msg.sender;
        auction.currentBidAmount = msg.value;

        emit AuctionBid(
            auctionId,
            msg.sender,
            auction.nftAddress,
            auction.tokenId,
            msg.value
        );
    }

    function closeAuction(uint256 auctionId) external nonReentrant {
        AuctionInfo storage auction = auctions[auctionId];

        if (auction.auctionEndTimestamp > block.timestamp) {
            revert AuctionNotFinished();
        }

        if (auction.currentBidder == address(0x0)) {
            IERC721(auction.nftAddress).safeTransferFrom(
                address(this),
                auction.seller,
                auction.tokenId
            );
        } else {
            _safeTransferETH(auction.seller, auction.currentBidAmount);

            IERC721(auction.nftAddress).transferFrom(
                address(this),
                auction.currentBidder,
                auction.tokenId
            );
        }

        emit AuctionClosed(
            auctionId,
            auction.seller,
            auction.currentBidder,
            auction.currentBidAmount
        );
    }

    function claimFees() public onlyOwner {
        _safeTransferETH(msg.sender, feeBalance);
        feeBalance = 0;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));

        if (!success) {
            revert EthTransferFailed();
        }
    }
}
