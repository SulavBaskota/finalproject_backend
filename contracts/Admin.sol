// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error NotSuperAdmin();

/*
 * May need to store admin username/userId for identification
 */

contract Admin {
    address public immutable superAdminAddress;
    mapping(address => bool) public adminAddressMap;

    modifier onlySuperAdmin() {
        if (msg.sender != superAdminAddress) revert NotSuperAdmin();
        _;
    }

    constructor() {
        superAdminAddress = msg.sender;
        adminAddressMap[msg.sender] = true;
    }

    function registerAdmin(address adminAddress) external onlySuperAdmin {
        adminAddressMap[adminAddress] = true;
    }

    function unregisterAdmin(address adminAddress) external onlySuperAdmin {
        adminAddressMap[adminAddress] = false;
    }

    function isAdmin(address adminAddress) public view returns (bool) {
        return adminAddressMap[adminAddress];
    }
}
