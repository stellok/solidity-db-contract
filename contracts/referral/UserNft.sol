// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../common/INft.sol";
import "../common/IReferral.sol";

contract UserNft is
    ERC721,
    ERC721URIStorage,
    Pausable,
    Ownable,
    INft,
    IReferral,
    AccessControl
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    //tokenId <==> level
    mapping(uint256 => uint16) levels;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); //
    bytes32 public constant REFERRAL_ROLE = keccak256("REFERRAL_ROLE");

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        //Make sure the tokenID > 0
        _tokenIdCounter.increment();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function currentID() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    string public baseURI;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721URIStorage, IERC165, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IReferral).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getLevel(uint256 tokenId) public view returns (uint16) {
        return levels[tokenId];
    }

    function setLevel(
        uint256 tokenId,
        uint16 level
    ) public onlyRole(REFERRAL_ROLE) {
        levels[tokenId] = level;
    }

    function mint(address to) public onlyRole(REFERRAL_ROLE) returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, "");
        return tokenId;
    }
}
