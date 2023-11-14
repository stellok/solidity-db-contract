// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPointsArgs {
    //The unit returned by this method must be wei
    function reward(uint16 _level) external view returns (uint256);

    function score(uint16 _level) external pure returns (uint256);

    function stage(uint16 _level) external pure returns (uint256);
}
