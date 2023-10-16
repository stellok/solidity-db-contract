// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 
contract Boxv1 {
    uint256 private value;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function increment0() public {
        value = value + 1;
        emit ValueChanged(value);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}