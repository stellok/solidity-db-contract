// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPointsArgs {
    function reward(uint16 _level) external pure returns (uint256);

    function score(uint16 _level) external pure returns (uint256);

    function stage(uint16 _level) external pure returns (uint256);
}
