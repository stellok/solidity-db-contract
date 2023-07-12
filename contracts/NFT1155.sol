// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";


contract ERC1155 is Context, ERC165, IERC1155, Ownable, ReentrancyGuard, IERC1155MetadataURI {
    using Address for address;

    mapping(uint256 => mapping(address => uint256)) private _balances;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    IERC20 public usdt;
    address public  feeAddress;
    uint256 public feePoint;

    using Strings for uint256;
    using SafeERC20 for IERC20;
    uint256  constant public feePointBase = 1000;

    event sellLog (address from_, uint256 tokenId_, uint256 price_, uint256 time_);
    event buyLog (address from_, address to_, uint256 tokenId_, uint256 amount_, uint256 price_);
    event cancelOrderLog (address account_, uint256 tokenId_);

    struct order {
        uint256 price;
        uint256 amount;
    }

    //    mapping(uint256 => order) public orders;
    mapping(uint256 => mapping(address => order)) public orders;
    mapping(uint256 => bool) public   disuseNFT;// 废弃

    //https://game.example/api/item/{id}.json
    constructor(string memory uri_, IERC20 usdtContract_, address owner_, uint256 feePoint_, address feeAddress_)  {
        usdt = usdtContract_;
        feeAddress = feeAddress_;
        feePoint = feePoint_;
        _setURI(uri_);
        _transferOwnership(owner_);
    }


    event deleteTokenId(uint256 tokenId_);

    function mint(address account_, uint256 tokenId, uint256 amount_) public onlyOwner {
        _mint(account_, tokenId, amount_, "");
    }


    function burn(
        address from_,
        uint256 id_,
        uint256 amount_) public onlyOwner {
        _burn(from_, id_, amount_);
    }

    function disuse(
        uint256 id_
    ) public onlyOwner {
        disuseNFT[id_] = true;
        emit deleteTokenId(id_);
    }


    function sell(uint256 tokenId_, uint256 amount_, uint256 price_) public nonReentrant {
        require(balanceOf(_msgSender(), tokenId_) >= amount_, "NFT not the owner");
        require(price_ > 0, "price not zero");
        require(amount_ > 0, "price not zero");
        orders[tokenId_][_msgSender()].price = price_;
        orders[tokenId_][_msgSender()].amount = amount_;
        emit sellLog(_msgSender(), tokenId_, price_, block.timestamp);
    }

    function cancelOrder(uint256 tokenId_) public nonReentrant {
        require(orders[tokenId_][_msgSender()].amount > 0, "order does not exist");
        delete orders[tokenId_][_msgSender()];
        emit cancelOrderLog(_msgSender(), tokenId_);
    }

    function buy(uint256 tokenId_, address sellAddr_, uint256 amount_, uint256 price_) public nonReentrant {
        require(orders[tokenId_][sellAddr_].amount > 0, "order does not exist");
        require(orders[tokenId_][sellAddr_].price == price_, "price  invalid");  // 防止卖家修改价格

        require(amount_ <= orders[tokenId_][sellAddr_].amount, "not enough quantity");
        orders[tokenId_][sellAddr_].amount -= amount_;
        if (feeAddress != address(0) && feePoint != 0) {
            uint256 txfee = amount_ * price_ * feePoint / feePointBase;
            usdt.safeTransferFrom(_msgSender(), feeAddress, txfee);
            usdt.safeTransferFrom(_msgSender(), sellAddr_, amount_ * orders[tokenId_][sellAddr_].price - txfee);
        } else {
            usdt.safeTransferFrom(_msgSender(), sellAddr_, orders[tokenId_][sellAddr_].price * amount_);
        }

        if (orders[tokenId_][sellAddr_].amount <= 0) {
            delete orders[tokenId_][sellAddr_];
        }
        // transferFrom(sellAddr_, _msgSender(), tokenId_);
        emit buyLog(sellAddr_, _msgSender(), tokenId_, amount_, orders[tokenId_][sellAddr_].price);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    override
    returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(disuseNFT[id] == false, "ERC1155:  id disuse");


        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);


        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        if (_balances[id][from] < orders[id][from].amount || _balances[id][from] == 0) {
            delete orders[id][from];
        }
        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }


    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}


    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}




