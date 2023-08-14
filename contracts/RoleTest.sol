// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleTest is AccessControl {
    bytes32 public constant PLATFORM = keccak256("PLATFORM"); // 平台
    bytes32 public constant ADMIN = keccak256("ADMIN"); // 平台
    bytes32 public constant OWNER = keccak256("OWNER"); //

    constructor(address user1, address user2, address user3) {
        _setRoleAdmin(ADMIN, OWNER);
        _setRoleAdmin(PLATFORM, ADMIN);

        _setupRole(PLATFORM, user1);
        _setupRole(ADMIN, user2);
        _setupRole(OWNER, user3);
    }

    function ownerCaller() public onlyRole(OWNER) {}

    function adminCaller() public onlyRole(ADMIN) {}

    function platFormCaller() public onlyRole(PLATFORM) {}
}
