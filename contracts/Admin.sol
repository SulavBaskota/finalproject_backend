// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error NotSuperAdmin();

/*
 * May need to store admin username/userId for identification
 */

contract Admin {
    address private immutable superAdminAddress;
    mapping(address => bool) private adminAddressMap;
    address[] private adminAddressArray;

    modifier onlySuperAdmin() {
        if (msg.sender != superAdminAddress) revert NotSuperAdmin();
        _;
    }

    constructor() {
        superAdminAddress = msg.sender;
        adminAddressMap[msg.sender] = true;
        adminAddressArray.push(superAdminAddress);
    }

    function registerAdmin(address adminAddress) external onlySuperAdmin {
        adminAddressMap[adminAddress] = true;
        adminAddressArray.push(adminAddress);
    }

    function unregisterAdmin(address adminAddress) external onlySuperAdmin {
        adminAddressMap[adminAddress] = false;
        uint length = adminAddressArray.length;
        for (uint i = 0; i < length; i++) {
            if (adminAddressArray[i] == adminAddress) {
                adminAddressArray[i] = adminAddressArray[length - 1];
                delete adminAddressArray[length - 1];
                length--;
                break;
            }
        }
    }

    function isAdmin(address adminAddress) external view returns (bool) {
        return adminAddressMap[adminAddress];
    }

    function isSuperAdmin() external view returns (bool) {
        return superAdminAddress == msg.sender;
    }

    function getAdmins()
        external
        view
        onlySuperAdmin
        returns (address[] memory)
    {
        return adminAddressArray;
    }
}
