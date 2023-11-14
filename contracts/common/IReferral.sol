// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IReferral is IERC721 {
    //Get the user's NFT level
    function getLevel(uint256 tokenId) external view returns (uint16);

    //Set the user's NFT level
    function setLevel(uint256 tokenId, uint16 level) external;

    //mint nft for user
    function mint(address user) external returns (uint256);
}
