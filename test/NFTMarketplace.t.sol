// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {MintableERC721} from "./mock/MintableERC721.sol";

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
}
