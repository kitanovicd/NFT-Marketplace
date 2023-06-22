# Introduction

This repository contains two smart contracts: **NFTMarketplace** and **AuctionNFTMarketplace**. These contracts are designed for managing the buying, selling, and auctioning of non-fungible tokens (NFTs). The contracts are written in Solidity and can be deployed on Ethereum-compatible blockchains.

## NFTMarketplace

The **NFTMarketplace** contract allows users to list NFTs for sale, buy NFTs, and claim funds from sold NFTs. Here are the key features and functions of the contract:
* Listing an NFT for sale: Users can list an NFT for sale by calling the ***listItem*** function and providing the NFT contract address, token ID, and the desired price.
* Unlisting an NFT: If the seller wants to remove an NFT from the marketplace, they can call the ***unlistItem*** function and provide the NFT contract address and token ID.
* Buying an NFT: Users can buy an NFT by calling the ***buyItem*** function and providing the NFT contract address and token ID. The function requires the buyer to send the exact amount of ether (ETH) equal to the listed price of the NFT.
* Claiming funds: After an NFT is sold, the seller can claim the funds by calling the ***claimFunds*** function. The contract keeps track of the amount to be claimed by each seller.

## AuctionNFTMarketplace
The **AuctionNFTMarketplace** contract enables users to auction their NFTs and participate in bidding. Here are the main features and functions of the contract:
* Starting an auction: Sellers can start an auction for an NFT by calling the ***startAuction*** function. They need to provide the NFT contract address, token ID, starting price, and the duration of the auction.
* Bidding: Users can place bids on ongoing auctions by calling the ***bid*** function and providing the auction ID. The bid amount must be greater than the current highest bid and the auction's end timestamp should not have passed.
* Closing an auction: When the auction duration ends, the seller can close the auction by calling the ***closeAuction*** function. The highest bidder will receive the NFT, and if there was a bid, the seller will receive the bid amount.
* Claiming fees: Only the owner of the contract can claim the accumulated fees by calling the ***claimFees*** function.

## Setup and Usage
To use these contracts, follow these steps:

1. Clone the repository:
```bash
git clone git@github.com:kitanovicd/NFT-Marketplace.git
```

2. Install dependencies:
```bash
cd NFT-Marketplace
npm install
```

3. Confiure env variables per **.env.example**

4. Deploy the contracts:
```bash
./script/deploy.sh
```