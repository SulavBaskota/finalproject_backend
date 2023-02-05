// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error NotSuperAdmin();
error CannotDeleteSuperAdmin();
error AdminAlreadyRegisterd();
error AddressNotAdmin();
error InvalidAddress();

/*
 * May need to store admin username/userId for identification
 */

contract Admin {
    address public immutable superAdminAddress;
    mapping(address => bool) public adminAddressMap;
    address[] public adminAddressArray;

    modifier onlySuperAdmin() {
        if (msg.sender != superAdminAddress) revert NotSuperAdmin();
        _;
    }

    constructor() {
        superAdminAddress = msg.sender;
        adminAddressMap[msg.sender] = true;
        adminAddressArray.push(msg.sender);
    }

    function registerAdmin(address adminAddress) external onlySuperAdmin {
        if (adminAddress == address(0)) revert InvalidAddress();
        if (adminAddressMap[adminAddress] == true)
            revert AdminAlreadyRegisterd();
        adminAddressMap[adminAddress] = true;
        adminAddressArray.push(adminAddress);
    }

    function unregisterAdmin(address adminAddress) external onlySuperAdmin {
        if (adminAddress == address(0)) revert InvalidAddress();
        if (adminAddress == superAdminAddress) revert CannotDeleteSuperAdmin();
        if (adminAddressMap[adminAddress] == false) revert AddressNotAdmin();
        delete adminAddressMap[adminAddress];
        uint length = adminAddressArray.length;
        for (uint i = 0; i < length; i++) {
            if (adminAddressArray[i] == adminAddress) {
                adminAddressArray[i] = adminAddressArray[
                    adminAddressArray.length - 1
                ];
                delete adminAddressArray[length - 1];
                adminAddressArray.pop();
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

    fallback() external {}
}
