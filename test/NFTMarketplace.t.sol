// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {MintableERC721} from "./mock/MintableERC721.sol";
import {NotAllowed} from "../src/NFTMarketplace.sol";
import {NotEnoughFunds} from "../src/NFTMarketplace.sol";

contract NFTMarketplaceTest is Test {
    address public seller;
    address public buyer;

    MintableERC721 public mintableERC721;
    NFTMarketplace public nftMarketplace;

    function setUp() public {
        seller = makeAddr("Seller");
        buyer = makeAddr("Buyer");

        vm.deal(seller, 100 ether);
        vm.deal(buyer, 100 ether);

        mintableERC721 = new MintableERC721();
        nftMarketplace = new NFTMarketplace();

        mintableERC721.mint(seller, 1);
    }

    function testSetup() public {
        assertEq(mintableERC721.ownerOf(1), seller);
    }

    function testListItem() public {
        vm.startPrank(seller);
        mintableERC721.approve(address(nftMarketplace), 1);
        nftMarketplace.listItem(address(mintableERC721), 1, 10 ether);
        vm.stopPrank();

        assertEq(mintableERC721.ownerOf(1), address(nftMarketplace));
        assertEq(
            nftMarketplace.getItemForSale(address(mintableERC721), 1).seller,
            seller
        );
        assertEq(
            nftMarketplace.getItemForSale(address(mintableERC721), 1).price,
            10 ether
        );
    }

    function testUnlistItem() public {
        vm.startPrank(seller);

        mintableERC721.approve(address(nftMarketplace), 1);
        nftMarketplace.listItem(address(mintableERC721), 1, 10 ether);
        nftMarketplace.unlistItem(address(mintableERC721), 1);

        vm.stopPrank();

        assertEq(mintableERC721.ownerOf(1), seller);
        assertEq(
            nftMarketplace.getItemForSale(address(mintableERC721), 1).seller,
            address(0)
        );
        assertEq(
            nftMarketplace.getItemForSale(address(mintableERC721), 1).price,
            0
        );
    }

    function testUnlistItemRevertNotAllowed() public {
        vm.startPrank(seller);

        mintableERC721.approve(address(nftMarketplace), 1);
        nftMarketplace.listItem(address(mintableERC721), 1, 10 ether);

        vm.stopPrank();
        vm.startPrank(buyer);

        vm.expectRevert(NotAllowed.selector);
        nftMarketplace.unlistItem(address(mintableERC721), 1);
        vm.stopPrank();
    }

    function testBuyItem() public {
        vm.startPrank(seller);
        mintableERC721.approve(address(nftMarketplace), 1);
        nftMarketplace.listItem(address(mintableERC721), 1, 10 ether);
        vm.stopPrank();

        vm.startPrank(buyer);

        uint256 buyerBalanceBefore = buyer.balance;
        uint256 nftMarketplaceBalanceBefore = address(nftMarketplace).balance;

        nftMarketplace.buyItem{value: 10 ether}(address(mintableERC721), 1);
        vm.stopPrank();

        uint256 buyerBalanceAfter = buyer.balance;
        uint256 nftMarketplaceBalanceAfter = address(nftMarketplace).balance;

        assertEq(
            nftMarketplaceBalanceAfter,
            nftMarketplaceBalanceBefore + 10 ether
        );
        assertEq(buyerBalanceAfter, buyerBalanceBefore - 10 ether);
        assertEq(mintableERC721.ownerOf(1), buyer);
        assertEq(
            nftMarketplace.getItemForSale(address(mintableERC721), 1).seller,
            address(0)
        );
        assertEq(
            nftMarketplace.getItemForSale(address(mintableERC721), 1).price,
            0
        );
        assertEq(nftMarketplace.amountToClaim(seller), 10 ether);
    }

    function testBuyRevertNotEnoughFunds() public {
        vm.startPrank(seller);
        mintableERC721.approve(address(nftMarketplace), 1);
        nftMarketplace.listItem(address(mintableERC721), 1, 10 ether);
        vm.stopPrank();

        vm.startPrank(buyer);
        vm.expectRevert(NotEnoughFunds.selector);
        nftMarketplace.buyItem{value: 9 ether}(address(mintableERC721), 1);
        vm.stopPrank();
    }

    function testClaimFunds() public {
        vm.startPrank(seller);
        mintableERC721.approve(address(nftMarketplace), 1);
        nftMarketplace.listItem(address(mintableERC721), 1, 10 ether);
        vm.stopPrank();

        vm.startPrank(buyer);
        nftMarketplace.buyItem{value: 10 ether}(address(mintableERC721), 1);
        vm.stopPrank();

        vm.startPrank(seller);

        uint256 sellerBalanceBefore = seller.balance;
        nftMarketplace.claimFunds();
        uint256 sellerBalanceAfter = seller.balance;

        vm.stopPrank();

        assertEq(sellerBalanceAfter, sellerBalanceBefore + 10 ether);
    }
}
