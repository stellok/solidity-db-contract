// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface Referral is IERC721 {
    //Get the user's NFT level
    function getLevel(address user) external view returns (uint256);

    //Set the user's NFT level
    function setLevel(address user, uint16 level) external;

    //mint nft for user
    function mint(address user) external;
}
