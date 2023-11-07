// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INft {
    //This method will be used again in synchronization
    //notify-app used
    function currentID() external view returns (uint256);
}
