// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./BlindAuction.sol";

contract BlindAuctionFactory {
    address public immutable adminContractAddress;
    address[] private blindAuctionAddressArray;

    event ContractCreated(address NewAuctionAddress);

    constructor(address _adminContractAddress) {
        adminContractAddress = _adminContractAddress;
    }

    function createBlindAuctionContract(
        uint startTime,
        uint endTime,
        uint minimumBid,
        string memory cid
    ) external {
        BlindAuction blindAuction = new BlindAuction(
            startTime,
            endTime,
            minimumBid,
            cid,
            adminContractAddress,
            payable(msg.sender)
        );
        blindAuctionAddressArray.push(address(blindAuction));
        emit ContractCreated(address(blindAuction));
    }

    function getBlindAuctionAddresses()
        external
        view
        returns (address[] memory)
    {
        return blindAuctionAddressArray;
    }

    fallback() external {}
}
