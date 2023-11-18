// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "../common/IPointsArgs.sol";

/* 
| stage | level  |       Score       | reward|
| :---: | :----: | :---------------: | :---: |
|   1   |  1到9  |       1000        |  10   |
|   2   | 10到19 |       1000        |  20   |
|   3   | 20到29 |       1000        |  40   |
|   4   | 30到39 |       1000        |  80   |
|   5   | 40到49 |       1000        |  160  |
|   6   | 50到59 |       1000        |  320  |
|   7   | 60到69 |       1000        |  640  |
|   8   | 70到79 |       1000        | 1280  |
|   9   | 80到89 |       1000        | 2560  |
|  10   | 90到99 |       1000        | 5120  |
|  11   |  100+  |       1000        | 10240 |
*/

contract Args is IPointsArgs {
    uint256 decimals = 10 ** 18;

    //1000000000000000000
    function reward(uint16 _level) public view returns (uint256) {
        if (_level >= 1 && _level <= 9) {
            return 10 * decimals;
        } else if (_level >= 10 && _level <= 19) {
            return 20 * decimals;
        } else if (_level >= 20 && _level <= 29) {
            return 40 * decimals;
        } else if (_level >= 30 && _level <= 39) {
            return 80 * decimals;
        } else if (_level >= 40 && _level <= 49) {
            return 160 * decimals;
        } else if (_level >= 50 && _level <= 59) {
            return 320 * decimals;
        } else if (_level >= 60 && _level <= 69) {
            return 640 * decimals;
        } else if (_level >= 70 && _level <= 79) {
            return 1280 * decimals;
        } else if (_level >= 80 && _level <= 89) {
            return 2560 * decimals;
        } else if (_level >= 90 && _level <= 99) {
            return 5120 * decimals;
        } else {
            return 10240 * decimals;
        }
    }

    function score(uint16 _level) public pure returns (uint) {
        return 1000;
    }

    function stage(uint16 _level) public pure returns (uint) {
        return (_level - 1) / 10 + 1;
    }
}
