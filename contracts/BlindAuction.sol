// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Admin.sol";

error TooEarly(uint256 time);
error TooLate(uint256 time);
error InvalidReveal();
error SellerCannotBid();
error OnlyOneBidAllowed();
error AuctionNotVerified();
error AuctionAlreadyVerified();
error AuctionAlreadyClosed();
error AuctionAlreadyRejected();
error NotAdmin();

/*
 * Might need to store username/userId for bidders and sellers for identification
 * This value can be encrypted using a SECRET_KEY
 * Should only be accessible to admin
 * A getter function with onlyAdmin modifier can be used for this
 *
 *
 * Another solution is for the user to verify that they are the winner
 * This can be done by using a function that compares the address of highestBidder to
 * the address of the user requesting verification only after revealEnd
 * the location provided by the user during this is sent to the admin dashboard along with the
 * auction and auction item addresses/Ids
 *
 *
 * Might have to create a method that allows a bidder to cancel their bid and return their deposit
 * before biddingEnd
 *
 *
 * Might need to return deposits to all bidders that did not reveal their bids
 * This should be done in the auctinEnd function
 * by using a loop to add the unrevealed bids to the pendingReturns mapping
 *
 *
 * Need to allow seller to specify MINIMUM_BID
 *
 *
 * Need to handle unsuccessful auction, which should allow bidders to withdraw their deposits
 * 
 * 
 * How to manage search? How to keep track of auctions for both sellers and buyer? Maybe create a watch-list,
 * have a section to show successful winning bids for bidder, and my-auctions for sellers
 */

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint256 deposit;
    }

    enum AuctionState {
        OPEN,
        CLOSED,
        PENDING,
        REJECTED
    } // 0, 1, 2, 3

    address payable public seller;
    uint256 public auctionId;
    uint256 public biddingTime;
    uint256 public revealTime;
    uint256 public biddingEnd;
    uint256 public revealEnd;
    address public adminContractAddress;
    string public rejectMessage;
    AuctionState public auctionState;

    mapping(address => Bid) public bids;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) pendingReturns;

    event AuctionEnded(address winner, uint256 highestBid);

    modifier onlyAdmin() {
        Admin adminContract = Admin(adminContractAddress);
        if (!adminContract.isAdmin(msg.sender)) revert NotAdmin();
        _;
    }

    modifier verifiedAuction() {
        if (auctionState == AuctionState.PENDING) {
            revert AuctionNotVerified();
        } else if (auctionState == AuctionState.REJECTED) {
            revert AuctionAlreadyRejected();
        }
        _;
    }

    modifier onlyBefore(uint256 time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }

    modifier onlyAfter(uint256 time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    modifier notSeller() {
        if (msg.sender == seller) revert SellerCannotBid();
        _;
    }

    modifier noPreviousBid() {
        if (bids[msg.sender].deposit != 0) revert OnlyOneBidAllowed();
        _;
    }

    modifier pendingVerification() {
        if (auctionState == AuctionState.OPEN) {
            revert AuctionAlreadyVerified();
        } else if (auctionState == AuctionState.CLOSED) {
            revert AuctionAlreadyClosed();
        } else if (auctionState == AuctionState.REJECTED) {
            revert AuctionAlreadyRejected();
        }
        _;
    }

    constructor(
        uint256 _auctionId,
        uint256 _biddingTime,
        uint256 _revealTime,
        address _adminContractAddress,
        address payable sellerAddress
    ) {
        auctionId = _auctionId;
        seller = sellerAddress;
        biddingTime = _biddingTime;
        revealTime = _revealTime;
        auctionState = AuctionState.PENDING;
        adminContractAddress = _adminContractAddress;
    }

    function verify() external onlyAdmin pendingVerification {
        auctionState = AuctionState.OPEN;
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingEnd + revealTime;
    }

    function rejectAuction(string memory _rejectMessage) external onlyAdmin pendingVerification {
        auctionState = AuctionState.REJECTED;
        rejectMessage = _rejectMessage;
    }

    /*
     * During Implementation, the parameters need to be changed 
     */
    function bid(
        uint256 value,
        uint256 trueBid,
        string memory secret
    ) external payable verifiedAuction onlyBefore(biddingEnd) notSeller noPreviousBid {
        bids[msg.sender] = Bid({
            // This needs to be done outside the contract during implementation
            blindedBid: keccak256(abi.encodePacked(value, trueBid, secret)),
            deposit: msg.value
        });
    }

    function reveal(
        uint256 value,
        uint256 trueBid,
        // this needs to be changed to bytes32 instead of string memory
        string memory secret
    ) external verifiedAuction onlyAfter(biddingEnd) onlyBefore(revealEnd) {
        uint256 refund;
        Bid storage bidToCheck = bids[msg.sender];
        if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, trueBid, secret))) {
            revert InvalidReveal();
        }
        refund = bidToCheck.deposit;
        if (bidToCheck.deposit >= trueBid) {
            if (placeBid(msg.sender, trueBid)) refund -= trueBid;
        }
        pendingReturns[msg.sender] += refund;
        bidToCheck.blindedBid = bytes32(0);
    }

    function withdraw() external verifiedAuction {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    function auctionEnd() external verifiedAuction onlyAfter(revealEnd) {
        if (auctionState == AuctionState.CLOSED) revert AuctionAlreadyClosed();
        emit AuctionEnded(highestBidder, highestBid);
        auctionState = AuctionState.CLOSED;
        seller.transfer(highestBid);
    }

    function placeBid(address bidder, uint256 value) internal returns (bool success) {
        // need to resolve for same bid conflict later
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }
}
