// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BlindAuction.sol";

error InvalidAuctionId();

/*
 * May need to adjust code to connect to a contract to store auction item details,
 * either in this contract or blind auction contract
 *
 *
 * Need to think about how to allow unsuccessful auctions to be reauctioned without having to re-enter
 * auction item details
 *
 *
 * One solution is to allow seller to enter contract address of the item while creating auction
 * Only seller/owner should be able to change item details
 * Owner needs to be changed when item is successfully auctioned
 *
 *
 * Might need to create a get function to return auction details using auction address
 */

contract BlindAuctionFactory {
    address public immutable adminContractAddress;
    mapping(uint256 => address) public auctionIdToAddress;

    constructor(address _adminContractAddress) {
        adminContractAddress = _adminContractAddress;
    }

    function createBlindAuctionContract(
        uint256 auctionId,
        uint256 biddingTime,
        uint256 revealTime
    ) external returns (address) {
        if (auctionIdToAddress[auctionId] != address(0))
            revert InvalidAuctionId();
        BlindAuction blindAuction = new BlindAuction(
            auctionId,
            biddingTime,
            revealTime,
            adminContractAddress,
            payable(msg.sender)
        );
        auctionIdToAddress[auctionId] = address(blindAuction);
        return address(blindAuction);
    }
}
