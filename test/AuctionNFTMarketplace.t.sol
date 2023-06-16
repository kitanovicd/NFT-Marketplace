// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/Errors.sol";
import {Test} from "forge-std/Test.sol";
import {AuctionNFTMarketplace} from "../src/AuctionNFTMarkeplace.sol";
import {MintableERC721} from "./mock/MintableERC721.sol";

contract AuctionNFTMarketplaceTest is Test {
    address public seller;
    address public bidder1;
    address public bidder2;
    address public winner;

    MintableERC721 public mintableERC721;
    AuctionNFTMarketplace public auctionNFTMarketplace;

    function setUp() public {
        seller = makeAddr("Seller");
        bidder1 = makeAddr("Bidder1");
        bidder2 = makeAddr("Bidder2");
        winner = makeAddr("Winner");

        vm.deal(seller, 100 ether);
        vm.deal(bidder1, 100 ether);
        vm.deal(bidder2, 100 ether);
        vm.deal(winner, 100 ether);

        mintableERC721 = new MintableERC721();
        auctionNFTMarketplace = new AuctionNFTMarketplace();

        mintableERC721.mint(seller, 1);
    }

    function testSetup() public {
        assertEq(mintableERC721.ownerOf(1), seller);
    }

    function testStartAuction() public {
        this.setUp();
        vm.startPrank(seller);

        uint256 duration = 1 days;
        uint256 startPrice = 10 ether;
        uint256 fee = (startPrice *
            auctionNFTMarketplace.AUCTION_FEE_PERCENTAGE()) / 100;
        uint256 sellerBalanceBefore = seller.balance;
        uint256 marketplaceBalanceBefore = address(auctionNFTMarketplace)
            .balance;
        uint256 marketplaceFeeBalanceBefore = auctionNFTMarketplace
            .feeBalance();

        mintableERC721.approve(address(auctionNFTMarketplace), 1);
        auctionNFTMarketplace.startAuction{value: fee}(
            address(mintableERC721),
            1,
            startPrice,
            duration
        );

        vm.stopPrank();

        uint256 sellerBalanceAfter = seller.balance;
        uint256 marketplaceBalanceAfter = address(auctionNFTMarketplace)
            .balance;
        uint256 marketplaceFeeBalanceAfter = auctionNFTMarketplace.feeBalance();

        AuctionNFTMarketplace.AuctionInfo
            memory auctionInfo = auctionNFTMarketplace.getAuction(0);

        assertEq(auctionInfo.seller, seller);
        assertEq(auctionInfo.nftAddress, address(mintableERC721));
        assertEq(auctionInfo.tokenId, 1);
        assertEq(auctionInfo.currentBidder, address(0x0));
        assertEq(auctionInfo.currentBidAmount, startPrice);
        assertEq(auctionInfo.auctionEndTimestamp, block.timestamp + duration);
        assertEq(mintableERC721.ownerOf(1), address(auctionNFTMarketplace));
        assertEq(
            address(auctionNFTMarketplace).balance,
            (startPrice * auctionNFTMarketplace.AUCTION_FEE_PERCENTAGE()) / 100
        );
        assertEq(sellerBalanceAfter, sellerBalanceBefore - fee);
        assertEq(marketplaceBalanceAfter, marketplaceBalanceBefore + fee);
        assertEq(marketplaceFeeBalanceAfter, marketplaceFeeBalanceBefore + fee);
    }

    function testBid() public {
        this.setUp();
        vm.startPrank(seller);

        uint256 startPrice = 10 ether;
        uint256 duration = 1 days;
        uint256 fee = (startPrice *
            auctionNFTMarketplace.AUCTION_FEE_PERCENTAGE()) / 100;

        mintableERC721.approve(address(auctionNFTMarketplace), 1);
        auctionNFTMarketplace.startAuction{value: fee}(
            address(mintableERC721),
            1,
            startPrice,
            duration
        );

        vm.stopPrank();
        vm.startPrank(bidder1);
        uint256 auctionBalanceBeforeFirstBid = address(auctionNFTMarketplace)
            .balance;
        uint256 bidder1BalanceBefore = bidder1.balance;
        uint256 sellerBalanceBeforeFirstBid = seller.balance;
        uint256 bidAmount1 = startPrice + 1;

        auctionNFTMarketplace.bid{value: bidAmount1}(0);
        vm.stopPrank();

        uint256 bidder1BalanceAfter = bidder1.balance;
        uint256 sellerBalanceAfterFirstBid = seller.balance;
        uint256 auctionBalanceAfterFirstBid = address(auctionNFTMarketplace)
            .balance;
        AuctionNFTMarketplace.AuctionInfo
            memory auctionInfo = auctionNFTMarketplace.getAuction(0);

        assertEq(auctionInfo.currentBidder, bidder1);
        assertEq(auctionInfo.currentBidAmount, bidAmount1);
        assertEq(
            auctionBalanceAfterFirstBid,
            auctionBalanceBeforeFirstBid + bidAmount1
        );
        assertEq(bidder1BalanceAfter, bidder1BalanceBefore - bidAmount1);
        assertEq(sellerBalanceAfterFirstBid, sellerBalanceBeforeFirstBid);

        vm.startPrank(bidder2);
        uint256 auctionBalanceBeforeSecondBid = address(auctionNFTMarketplace)
            .balance;
        uint256 bidder2BalanceBefore = bidder2.balance;
        uint256 bidAmount2 = bidAmount1 + 1;
        auctionNFTMarketplace.bid{value: bidAmount2}(0);
        vm.stopPrank();

        bidder1BalanceAfter = bidder1.balance;
        uint256 bidder2BalanceAfter = bidder2.balance;
        uint256 auctionBalanceAfterSecondBid = address(auctionNFTMarketplace)
            .balance;
        auctionInfo = auctionNFTMarketplace.getAuction(0);

        assertEq(auctionInfo.currentBidder, bidder2);
        assertEq(auctionInfo.currentBidAmount, bidAmount2);
        assertEq(
            auctionBalanceAfterSecondBid,
            auctionBalanceBeforeSecondBid + bidAmount2 - bidAmount1
        );
        assertEq(bidder2BalanceAfter, bidder2BalanceBefore - bidAmount2);
        assertEq(bidder1BalanceAfter, bidder1BalanceBefore);
    }

    function testBidRevertAuctionFinished() public {
        this.setUp();
        vm.startPrank(seller);

        uint256 startPrice = 10 ether;
        uint256 duration = 1 days;
        uint256 fee = (startPrice *
            auctionNFTMarketplace.AUCTION_FEE_PERCENTAGE()) / 100;

        mintableERC721.approve(address(auctionNFTMarketplace), 1);
        auctionNFTMarketplace.startAuction{value: fee}(
            address(mintableERC721),
            1,
            startPrice,
            duration
        );

        vm.stopPrank();
        vm.startPrank(bidder1);
        vm.warp(block.timestamp + duration + 1);
        vm.expectRevert(AuctionFinished.selector);
        auctionNFTMarketplace.bid{value: startPrice + 1}(0);

        vm.stopPrank();
    }

    function testBidRevertNotEnoughFunds() public {
        this.setUp();
        vm.startPrank(seller);

        uint256 startPrice = 10 ether;
        uint256 duration = 1 days;
        uint256 fee = (startPrice *
            auctionNFTMarketplace.AUCTION_FEE_PERCENTAGE()) / 100;

        mintableERC721.approve(address(auctionNFTMarketplace), 1);
        auctionNFTMarketplace.startAuction{value: fee}(
            address(mintableERC721),
            1,
            startPrice,
            duration
        );

        vm.stopPrank();
        vm.startPrank(bidder1);
        vm.expectRevert(NotEnoughFunds.selector);
        auctionNFTMarketplace.bid{value: startPrice - 1}(0);

        vm.stopPrank();
    }

    function testCloseAuction() public {
        this.setUp();
        vm.startPrank(seller);

        uint256 startPrice = 10 ether;
        uint256 duration = 1 days;
        uint256 fee = (startPrice *
            auctionNFTMarketplace.AUCTION_FEE_PERCENTAGE()) / 100;

        mintableERC721.approve(address(auctionNFTMarketplace), 1);
        auctionNFTMarketplace.startAuction{value: fee}(
            address(mintableERC721),
            1,
            startPrice,
            duration
        );

        vm.stopPrank();
        vm.startPrank(bidder1);

        uint256 bidAmount = startPrice + 1;
        auctionNFTMarketplace.bid{value: bidAmount}(0);

        vm.stopPrank();
        vm.startPrank(seller);
        vm.warp(block.timestamp + duration + 1);

        uint256 auctionNFTMarketplaceBalanceBefore = address(
            auctionNFTMarketplace
        ).balance;
        uint256 sellerBalanceBefore = seller.balance;

        auctionNFTMarketplace.closeAuction(0);

        uint256 auctionNFTMarketplaceBalanceAfter = address(
            auctionNFTMarketplace
        ).balance;
        uint256 sellerBalanceAfter = seller.balance;

        assertEq(
            auctionNFTMarketplaceBalanceAfter,
            auctionNFTMarketplaceBalanceBefore - bidAmount
        );
        assertEq(sellerBalanceAfter, sellerBalanceBefore + bidAmount);
        assertEq(mintableERC721.ownerOf(1), bidder1);
    }

    function testCloseAuctionWithoutBids() public {
        this.setUp();
        vm.startPrank(seller);

        uint256 startPrice = 10 ether;
        uint256 duration = 1 days;
        uint256 fee = (startPrice *
            auctionNFTMarketplace.AUCTION_FEE_PERCENTAGE()) / 100;

        mintableERC721.approve(address(auctionNFTMarketplace), 1);
        auctionNFTMarketplace.startAuction{value: fee}(
            address(mintableERC721),
            1,
            startPrice,
            duration
        );

        vm.stopPrank();
        vm.startPrank(seller);
        vm.warp(block.timestamp + duration + 1);

        uint256 auctionNFTMarketplaceBalanceBefore = address(
            auctionNFTMarketplace
        ).balance;
        uint256 sellerBalanceBefore = seller.balance;

        auctionNFTMarketplace.closeAuction(0);

        uint256 auctionNFTMarketplaceBalanceAfter = address(
            auctionNFTMarketplace
        ).balance;
        uint256 sellerBalanceAfter = seller.balance;

        assertEq(
            auctionNFTMarketplaceBalanceAfter,
            auctionNFTMarketplaceBalanceBefore
        );
        assertEq(sellerBalanceAfter, sellerBalanceBefore);
        assertEq(mintableERC721.ownerOf(1), seller);
    }

    function testCloseAuctionRevertAuctionNotFinished() public {
        this.setUp();
        vm.startPrank(seller);

        uint256 startPrice = 10 ether;
        uint256 duration = 1 days;
        uint256 fee = (startPrice *
            auctionNFTMarketplace.AUCTION_FEE_PERCENTAGE()) / 100;

        mintableERC721.approve(address(auctionNFTMarketplace), 1);
        auctionNFTMarketplace.startAuction{value: fee}(
            address(mintableERC721),
            1,
            startPrice,
            duration
        );

        vm.stopPrank();
        vm.startPrank(seller);
        vm.warp(block.timestamp + duration - 1);
        vm.expectRevert(AuctionNotFinished.selector);
        auctionNFTMarketplace.closeAuction(0);

        vm.stopPrank();
    }

    function testCloseAuctionRevertOnlyOwnerCanCloseAuction() public {
        this.setUp();
        vm.startPrank(seller);

        uint256 startPrice = 10 ether;
        uint256 duration = 1 days;
        uint256 fee = (startPrice *
            auctionNFTMarketplace.AUCTION_FEE_PERCENTAGE()) / 100;

        mintableERC721.approve(address(auctionNFTMarketplace), 1);
        auctionNFTMarketplace.startAuction{value: fee}(
            address(mintableERC721),
            1,
            startPrice,
            duration
        );

        vm.stopPrank();
        vm.startPrank(bidder1);
        vm.warp(block.timestamp + duration + 1);
        vm.expectRevert(OnlyOwnerCanCloseAuction.selector);
        auctionNFTMarketplace.closeAuction(0);

        vm.stopPrank();
    }
}
