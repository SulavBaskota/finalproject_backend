// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Admin.sol";

/**Errors */
error NotAdmin();
error InvalidBid();
error InvalidReveal();
error SellerCannotBid();
error OnlyOneBidAllowed();
error AuctionNotVerified();
error TooLate(uint time);
error TooEarly(uint time);
error InvalidAuctionPeriod();
error AuctionAlreadyClosed();
error AuctionAlreadyVerified();
error AuctionAlreadyRejected();

contract BlindAuction {
    /**Type Declarations */
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    enum AuctionState {
        UNVERIFIED,
        REJECTED,
        OPEN,
        SUCCESSFUL,
        FAILED
    } // 0, 1, 2, 3, 4

    /**State Variables */
    string private rejectMessage;
    uint private immutable endTime;
    uint private immutable startTime;
    uint private immutable mimimumBid;
    uint private immutable revealTime;
    string private cid;
    address payable private immutable seller;
    address private immutable adminContractAddress;
    address[] private bidders;

    uint private constant REVEAL_PERIOD = 240; // 4 minutes
    uint private constant MINIMUM_VERIFICATION_DURATION = 120; // 2 minutes
    uint private constant MINIMUM_AUCTION_DURATION = 240; // 4 minutes

    AuctionState private auctionState;

    mapping(address => Bid) private bids;

    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) private pendingReturns;

    /**Events */
    event AuctionFailed();
    event AuctionVerified(address verifiedBy);
    event AuctionRejected(string reason, address rejectedBy);
    event AuctionSuccessful(address winner, uint highestBid);

    /**Modifiers */
    modifier onlyAdmin() {
        Admin adminContract = Admin(adminContractAddress);
        if (!adminContract.isAdmin(msg.sender)) revert NotAdmin();
        _;
    }

    modifier verifiedAuction() {
        if (auctionState == AuctionState.UNVERIFIED) {
            revert AuctionNotVerified();
        } else if (auctionState == AuctionState.REJECTED) {
            revert AuctionAlreadyRejected();
        }
        _;
    }

    modifier onlyBefore(uint time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }

    modifier onlyAfter(uint time) {
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
        } else if (
            auctionState == AuctionState.SUCCESSFUL ||
            auctionState == AuctionState.FAILED
        ) {
            revert AuctionAlreadyClosed();
        } else if (auctionState == AuctionState.REJECTED) {
            revert AuctionAlreadyRejected();
        }
        _;
    }

    /**Constructor */
    constructor(
        uint _startTime,
        uint _endTime,
        uint _minimumBid,
        string memory _cid,
        address _adminContractAddress,
        address payable sellerAddress
    ) {
        if (
            _startTime <= block.timestamp + MINIMUM_VERIFICATION_DURATION ||
            _endTime < _startTime + MINIMUM_AUCTION_DURATION
        ) revert InvalidAuctionPeriod();
        seller = sellerAddress;
        startTime = _startTime;
        endTime = _endTime;
        revealTime = _endTime + REVEAL_PERIOD;
        auctionState = AuctionState.UNVERIFIED;
        mimimumBid = _minimumBid;
        cid = _cid;
        adminContractAddress = _adminContractAddress;
    }

    function verifyAuction()
        external
        onlyAdmin
        pendingVerification
        onlyBefore(startTime)
    {
        auctionState = AuctionState.OPEN;
        emit AuctionVerified(msg.sender);
    }

    function rejectAuction(
        string memory _rejectMessage
    ) external onlyAdmin pendingVerification {
        auctionState = AuctionState.REJECTED;
        rejectMessage = _rejectMessage;
        emit AuctionRejected(_rejectMessage, msg.sender);
    }

    function bid(
        bytes32 _blindedBid
    )
        external
        payable
        verifiedAuction
        onlyAfter(startTime)
        onlyBefore(endTime)
        notSeller
        noPreviousBid
    {
        if (msg.value < mimimumBid) revert InvalidBid();
        bids[msg.sender] = Bid({blindedBid: _blindedBid, deposit: msg.value});
        bidders.push(msg.sender);
    }

    function reveal(
        uint trueBid,
        bytes32 secret
    ) external verifiedAuction onlyAfter(endTime) onlyBefore(revealTime) {
        uint refund;
        Bid storage bidToCheck = bids[msg.sender];
        if (
            bidToCheck.blindedBid !=
            keccak256(abi.encodePacked(trueBid, secret))
        ) {
            revert InvalidReveal();
        }
        refund = bidToCheck.deposit;
        if (bidToCheck.deposit >= trueBid) {
            if (placeBid(msg.sender, trueBid)) refund -= trueBid;
        }
        pendingReturns[msg.sender] += refund;
        bidToCheck.blindedBid = bytes32(0);

        uint length = bidders.length;
        for (uint i = 0; i < length; i++) {
            if (bidders[i] == msg.sender) {
                bidders[i] = bidders[bidders.length - 1];
                delete bidders[length - 1];
                bidders.pop();
                break;
            }
        }
    }

    function withdraw() external verifiedAuction onlyAfter(revealTime) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    function auctionEnd() external verifiedAuction onlyAfter(revealTime) {
        if (
            auctionState == AuctionState.SUCCESSFUL ||
            auctionState == AuctionState.FAILED
        ) revert AuctionAlreadyClosed();
        refundBids();
        if (highestBidder != address(0)) {
            auctionState = AuctionState.SUCCESSFUL;
            emit AuctionSuccessful(highestBidder, highestBid);
            seller.transfer(highestBid);
        } else {
            auctionState = AuctionState.FAILED;
            emit AuctionFailed();
        }
    }

    function placeBid(
        address bidder,
        uint value
    ) internal returns (bool success) {
        if (value < mimimumBid || value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    function refundBids() internal {
        for (uint i = 0; i < bidders.length; i++) {
            address bidder = bidders[i];
            pendingReturns[bidder] += bids[bidder].deposit;
            bids[bidder].blindedBid = bytes32(0);
        }
        delete bidders;
    }

    function getAuctionDetails()
        external
        view
        returns (
            address _contractAddress,
            uint _startTime,
            uint _endTime,
            uint _minimumBid,
            string memory _cid,
            address _seller,
            AuctionState _auctionState
        )
    {
        return (
            address(this),
            startTime,
            endTime,
            mimimumBid,
            cid,
            seller,
            auctionState
        );
    }

    fallback() external {}
}
