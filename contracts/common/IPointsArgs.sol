// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPointsArgs {
    //这个方法返回的单位必须是wei
    function reward(uint16 _level) external view returns (uint256);

    function score(uint16 _level) external pure returns (uint256);

    function stage(uint16 _level) external pure returns (uint256);
}
