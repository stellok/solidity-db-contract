// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBidding {
    //return the subscription quantity,
    function viewSubscribe(address) external view returns (uint256);

    function transferAmount(uint256 amount) external;
}