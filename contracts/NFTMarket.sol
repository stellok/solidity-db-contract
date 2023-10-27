// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFTMarket is ERC721Holder, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public usdt;

    event List(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    event Purchase(
        address indexed buyer,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 fee,
        uint256 price
    );
    event Revoke(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId
    );
    event Update(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 newPrice
    );

    event SoldOut(address nftAddr, uint256 tokenId);

    //Define the order structure
    struct Order {
        address owner;
        uint256 price;
    }
    //NFT Order mapping
    mapping(address => mapping(uint256 => Order)) public nftList;

    uint256 public persent;
    address public feeAddr;

    function setTransactionFee(uint8 _persent) public onlyOwner {
        require(_persent <= 100, "persent Must be between 1 and 100");
        persent = _persent;
    }

    function setTransactionAddr(address _feeAddr) public onlyOwner {
        feeAddr = _feeAddr;
    }

    constructor(IERC20 _usdt) {
        usdt = _usdt;
    }

    // fallback() external payable {}

    function batchList(
        address _nftAddr,
        uint256[] memory _tokenId,
        uint256[] memory _price
    ) public {
        require(
            _tokenId.length == _price.length,
            "_tokenId length !=_price length"
        );
        for (uint i = 0; i < _tokenId.length; i++) {
            list(_nftAddr, _tokenId[i], _price[i]);
        }
    }

    function batchRevoke(address _nftAddr, uint256[] memory _tokenId) public {
        for (uint i = 0; i < _tokenId.length; i++) {
            revoke(_nftAddr, _tokenId[i]);
        }
    }

    function batchPurchase(address _nftAddr, uint256[] memory _tokenId) public {
        IERC721 _nft = IERC721(_nftAddr);
        for (uint i = 0; i < _tokenId.length; i++) {
            if (_nft.ownerOf(_tokenId[i]) == address(this)) {
                purchase(_nftAddr, _tokenId[i]);
            } else {
                emit SoldOut(_nftAddr, _tokenId[i]);
            }
        }
    }

    //Pending order: The seller lists the NFT, the contract address is _nftAddr, the tokenId is _tokenId, and the price _price is Ethereum (the unit is wei）
    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        IERC721 _nft = IERC721(_nftAddr); //Declare IERC721 interface contract variables
        require(
            _nft.ownerOf(_tokenId) == msg.sender,
            "You do not own this token ID"
        );

        require(_price > 0); // The price is greater than 0

        Order storage _order = nftList[_nftAddr][_tokenId]; //Set NF holders and prices
        _order.owner = msg.sender;
        _order.price = _price;
        // Transfer NFTs to contracts

        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // Release the list event
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    // Purchase: The buyer buys the NFT, the contract is _nftAddr, the tokenId is _tokenId, and ETH is included when calling the function
    function purchase(address _nftAddr, uint256 _tokenId) public {
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFTs are in the contract

        Order storage _order = nftList[_nftAddr][_tokenId]; // Get the order
        require(_order.price > 0, "Invalid Price"); // The NFT price is greater than 0
        // require(msg.value >= _order.price, "Increase price"); // The purchase price is greater than the list price
        // Declare the ier c721 interface contract variable

        // Transfer the NFT to the buyer
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        // Transfer ETH to the seller and refund excess ETH to the buyer

        // payable(_order.owner).transfer(_order.price);
        // payable(msg.sender).transfer(msg.value - _order.price);

        // Transfer usdt
        usdt.safeTransferFrom(_msgSender(), address(this), _order.price);

        uint256 price = _order.price;

        uint256 fee;
        //Transfer fee
        if (feeAddr != address(0) && persent > 0) {
            fee = (_order.price * persent) / 100;
            usdt.safeTransfer(feeAddr, fee);
            price -= fee;
        }

        //Transfer to buyer
        usdt.safeTransfer(_order.owner, price);

        // Release the purchase event
        emit Purchase(msg.sender, _nftAddr, _tokenId, fee, _order.price);

        delete nftList[_nftAddr][_tokenId]; // Delete Order
    }

    // Cancelled: The seller cancels the pending order
    function revoke(address _nftAddr, uint256 _tokenId) public {
        Order storage _order = nftList[_nftAddr][_tokenId]; // Get the order
        require(_order.owner == msg.sender, "Not Owner"); // Must be initiated by the holder
        // Declare the ier c721 interface contract variable
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFTs are in the contract

        // Transfer the NFT to the seller
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete nftList[_nftAddr][_tokenId]; // Delete Order

        // Release the revoke event
        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    // Adjust Price: The seller adjusts the pending order price
    function update(
        address _nftAddr,
        uint256 _tokenId,
        uint256 _newPrice
    ) public {
        require(_newPrice > 0, "Invalid Price"); // The NFT price is greater than 0
        Order storage _order = nftList[_nftAddr][_tokenId]; // Get the order
        require(_order.owner == msg.sender, "Not Owner"); //Must be initiated by the holder
        // Declare the ier c721 interface contract variable
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); // NFTs are in the contract
        // Adjust NFT prices
        _order.price = _newPrice;
        // Release the update event
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }

    function inOrder(
        address _nftAddr,
        uint256 _tokenId
    ) public view returns (Order memory) {
        return nftList[_nftAddr][_tokenId];
    }
}
