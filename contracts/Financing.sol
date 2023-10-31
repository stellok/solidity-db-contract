// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./NFT721Impl.sol";
import "./Operation.sol";
import "./common/FinancType.sol";
import "./common/IBidding.sol";

//Equity financing
contract Financing is AccessControl, Pausable, ReentrancyGuard, FinancType {
    using SafeERC20 for IERC20;
    bool public saleIsActive;
    IERC20 public usdt;
    NFT721Impl public receiptNFT; //Equity NFT
    NFT721Impl public shareNFT; //equityNFT
    IBidding public bidding; //equityNFT

    address public dividends;

    uint256 public maxNftAMOUNT = 10;

    //Power pledge time
    bool public electrStakeLock;
    bool public isClaimRemainBuild;
    enum ActionChoices {
        INIT,
        whitelistPayment, //Whitelist
        publicSale, //Public sale
        publicSaleFailed, //The public sale failed
        startBuild, //Start building
        remainPayment, //Tail payment
        Bargain, //Pick up leaks
        FINISH, //finish
        FAILED //fail
    }

    ActionChoices public schedule;

    mapping(address => bool) paidUser; //Paid-up users

    address public platformAddr; //Platform management address
    address public platformFeeAddr; //Platform payment address
    address public founderAddr; //founder
    uint256 public issuedTotalShare; //Total number of shares issued
    uint256 public publicSaleTotalSold; //Total number of the first stage
    uint256 public whitelistPaymentTime; //Whitelist start time
    uint256 public publicSaleTime; //Public sale start time
    uint256 startBuildTime; //Start of construction time
    uint256 bargainTime; //Pick up the start time
    uint256 public remainPaymentTime; //Whitelist start time
    uint256 public electrStartTime; // The last power settlement time
    uint256 public operationStartTime; //The last O&M settlement time
    uint256 public insuranceStartTime; //Time of settlement of the insurance sub-insurance
    uint256 public spvStartTime; // Time of settlement of the insurance sub-insurance
    uint256 public trustStartTime; // Time of settlement of the trust Manger start time

    uint256 public dividendsExpire;
    uint256 public reserveFund;

    event claimFirstBuildFeeLog(
        address energyAddr_,
        uint256 firstFee_,
        uint256 receiveTime_
    );
    event claimRemainBuildFeeLog(
        address energyAddr_,
        uint256 firstFee_,
        uint256 receiveTime_
    );

    event buildInsuranceReceiveLog(
        address addr_,
        uint256 amount_,
        uint256 time_
    );
    event operationsReceiveLog(address addr_, uint256 amount_, uint256 time_);
    event spvReceiveLog(address addr_, uint256 amount_, uint256 time_);
    event electrStakeLog(address feeAddr, uint256 amount, uint256 time_);
    event redeemRemainPaymentLog(uint256 tokenId_, uint256 amount_);
    event remainBargainLog(
        address account_,
        uint256 balance_,
        uint256 price_,
        uint256 time_
    );
    event remainPaymentLog(
        address account_,
        uint256 amount_,
        uint256 sharePrice,
        uint256 time_
    );
    event whiteListPaymentLog(
        address account_,
        uint256 amount_,
        uint256 price_,
        uint256 time_
    );
    event redeemPublicSaleLog(uint256 tokenId_, uint256 amount_);

    event energyReceiveLog(
        address addr,
        uint256 mouth,
        uint256 amount_,
        uint256 time_
    );
    event startPublicSaleLog(uint256 unpaid_, uint256 time_);
    event startBargainLog(uint256 unpaid_, uint256 time_);
    event publicSaleLog(
        address,
        uint256 amount_,
        uint256 price_,
        uint256 time_
    );
    event checkPublicSaleLog(uint256 time_, ActionChoices);
    event checkRemainPaymentLog(uint256 tokenId, uint256 time_);
    event insuranceReceiveLog(
        address energyAddr_,
        uint256 amount_,
        uint256 time_
    );
    event whetherFirstPaymentFinishLog(bool, uint256 time_);
    event whetherFinishLog(bool, uint256 time_);

    constructor(
        IERC20 usdtAddr_,
        IBidding bidding_, //Tender contracts
        address platformFeeAddr_,
        address founderAddr_,
        FeeType memory feeList_, // fees
        AddrType memory addrList_, // address
        LimitTimeType memory limitTimeList_, // times
        ShareType memory shareList_, // Share
        string memory uri_1,
        string memory uri_2,
        uint256 expire,
        uint256 reserveFund_
    ) {
        dividendsExpire = expire;
        reserveFund = reserveFund_;

        whitelistPaymentTime = block.timestamp;
        saleIsActive = false;
        shareType = shareList_;
        addrType = addrList_;
        limitTimeType = limitTimeList_;
        feeType = feeList_;
        // feeList_ field check
        require(feeList_.firstBuildFee != 0, "firstBuildFee == 0"); //First build model
        require(feeList_.remainBuildFee != 0, "remainBuildFee == 0"); //Remaining construction money
        require(feeList_.operationsFee != 0, "operationsFee == 0"); //Shipping costs
        require(feeList_.electrFee != 0, "electrFee== 0"); //Electricity
        require(feeList_.buildInsuranceFee != 0, "buildInsuranceFee == 0"); //Construction insurance premium
        require(feeList_.insuranceFee != 0, "insuranceFee == 0"); //Warranty fee
        require(feeList_.spvFee != 0, "spvFee== 0"); //Trust management fees
        require(address(usdtAddr_) != address(0), "usdt Can not be empty");
        require(
            platformFeeAddr_ != address(0),
            "platformFeeAddr_ Can not be empty"
        );

        platformAddr = _msgSender(); //Platform management address
        platformFeeAddr = platformFeeAddr_; //Platform payment address

        founderAddr = founderAddr_;
        require(
            shareType.sharePrice ==
                shareType.firstSharePrice + //30
                    shareType.remainSharePrice, //70
            "sharePrice verification failed"
        ); //Price verification failed
        require(
            shareType.totalShare ==
                shareType.financingShare +
                    shareType.founderShare +
                    shareType.platformShare,
            "share verification failed"
        );

        address receiptAddr = deployNFT("DB", "DB");
        address shareAddr = deployNFT("shareNFT", "shareNFT");
        receiptNFT = NFT721Impl(receiptAddr);
        receiptNFT.setBaseURI(uri_1);
        shareNFT = NFT721Impl(shareAddr);
        shareNFT.setBaseURI(uri_2);
        bidding = bidding_;
        usdt = usdtAddr_;
        schedule = ActionChoices.whitelistPayment;
    }

    function deployDividends() internal returns (address) {
        bytes memory bytecode = type(Operation).creationCode;
        bytes memory initCode = abi.encodePacked(
            bytecode,
            abi.encode(
                reserveFund,
                usdt,
                shareNFT,
                shareType.totalShare,
                dividendsExpire,
                operationStartTime,
                spvStartTime,
                trustStartTime,
                electrStartTime,
                insuranceStartTime,
                feeType,
                addrType,
                limitTimeType
            )
        );
        bytes32 shareSalt = keccak256(abi.encodePacked(address(this), "share"));
        address deployedContract;
        assembly {
            deployedContract := create2(
                0,
                add(initCode, 32),
                mload(initCode),
                shareSalt
            )
        }
        return deployedContract;
    }

    function deployNFT(
        string memory name_,
        string memory symbol_
    ) internal returns (address) {
        bytes memory bytecode = type(NFT721Impl).creationCode;
        bytes memory initCode = abi.encodePacked(
            bytecode,
            abi.encode(name_, symbol_)
        );
        bytes32 shareSalt = keccak256(abi.encodePacked(address(this), "share"));
        address deployedContract;
        assembly {
            deployedContract := create2(
                0,
                add(initCode, 32),
                mload(initCode),
                shareSalt
            )
        }
        return deployedContract;
    }

    //Whitelist payments
    function whiteListPayment() public nonReentrant {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.whitelistPayment, "not PAID status");
        require(shareType.financingShare > publicSaleTotalSold, "sold out");
        require(!paidUser[_msgSender()], " Cannot participate repeatedly"); //Participation cannot be repeated
        paidUser[_msgSender()] = true;
        //Cannot be less than zero
        require(
            whitelistPaymentTime + limitTimeType.publicSaleLimitTime >
                block.timestamp,
            "time expired"
        );
        //View the staking status of the bidding contract user quantity, status,
        uint256 amount = bidding.viewSubscribe(_msgSender());
        //Must be locked
        require(amount > 0, "Not yet subscribed");
        //Quantity greater than 0
        if (shareType.financingShare - publicSaleTotalSold < amount) {
            amount = shareType.financingShare - publicSaleTotalSold;
        }
        publicSaleTotalSold += amount;
        uint256 gAmout = amount * shareType.stakeSharePrice;
        bidding.transferAmount(gAmout);
        //At the same time, the tender contract is notified to release the deposit
        usdt.safeTransferFrom(
            _msgSender(),
            address(this),
            amount * (shareType.firstSharePrice - shareType.stakeSharePrice)
        );
        emit whiteListPaymentLog(
            _msgSender(),
            amount,
            (shareType.firstSharePrice - shareType.stakeSharePrice),
            block.timestamp
        );
        // Minting voucher NFTs
        receiptNFT.mint(_msgSender(), amount);
        _whetherFirstPaymentFinish();
    }

    //Check if the down payment is complete
    function _whetherFirstPaymentFinish() private {
        if (publicSaleTotalSold >= shareType.financingShare) {
            startBuildTime = block.timestamp;
            schedule = ActionChoices.startBuild;
            emit whetherFirstPaymentFinishLog(true, block.timestamp);
        }
    }

    //Check whether the first payment was successful
    function checkWhiteList() public nonReentrant {
        require(schedule == ActionChoices.whitelistPayment, "not PAID status");
        require(
            whitelistPaymentTime + limitTimeType.whitelistPaymentLimitTime <
                block.timestamp &&
                whitelistPaymentTime != 0,
            "time expired"
        );
        if (publicSaleTotalSold < shareType.financingShare) {
            uint256 unpaid = shareType.financingShare - publicSaleTotalSold;
            schedule = ActionChoices.publicSale;
            emit startPublicSaleLog(unpaid, block.timestamp);
            publicSaleTime = block.timestamp;
        } else {
            _whetherFirstPaymentFinish();
        }
    }

    function publicSaleEstimate(uint256 amount_) public view returns (uint256) {
        if (shareType.financingShare - publicSaleTotalSold < amount_) {
            amount_ = shareType.financingShare - publicSaleTotalSold;
        }
        uint256 mAmount = amount_ *
            (shareType.firstSharePrice - shareType.stakeSharePrice);
        return mAmount;
    }

    function publicSale(uint256 amount_) public nonReentrant {
        require(schedule == ActionChoices.publicSale, "not publicSale status");
        require(
            amount_ <= maxNftAMOUNT && amount_ > 0,
            "amount Limit Exceeded"
        ); //Limit exceeded
        //Determine the status
        require(
            shareType.financingShare > publicSaleTotalSold,
            "cannot be less than zero"
        );

        require(
            publicSaleTime + limitTimeType.publicSaleLimitTime >
                block.timestamp,
            "time expired"
        );
        require(
            shareType.firstSharePrice > shareType.stakeSharePrice,
            "firstSharePrice > stakeSharePrice"
        );
        if (shareType.financingShare - publicSaleTotalSold < amount_) {
            amount_ = shareType.financingShare - publicSaleTotalSold;
        }
        publicSaleTotalSold += amount_;
    
        // Turn over 5% of the subscription
        uint256 gAmout = amount_ * shareType.stakeSharePrice;
        bidding.transferAmount(gAmout);

        uint256 mAmount = amount_ *
            (shareType.firstSharePrice - shareType.stakeSharePrice);

        usdt.safeTransferFrom(
            _msgSender(),
            address(this),
            mAmount //
        );

        emit publicSaleLog(_msgSender(), amount_, mAmount, block.timestamp);
        // 铸造nft
        receiptNFT.mint(_msgSender(), amount_);
        _whetherFirstPaymentFinish();
    }

    //Check the public sale
    function checkPublicSale() public nonReentrant {
        require(schedule == ActionChoices.publicSale, "not publicSale status");
        require(
            publicSaleTime + limitTimeType.publicSaleLimitTime <
                block.timestamp,
            "time expired"
        );
        if (shareType.financingShare <= publicSaleTotalSold) {
            _whetherFirstPaymentFinish();
        } else {
            schedule = ActionChoices.publicSaleFailed;
            emit whetherFirstPaymentFinishLog(false, block.timestamp);
        }
    }

    //Return to the public sale
    function redeemPublicSale(
        uint256[] memory tokenIdList
    ) public nonReentrant {
        require(
            schedule == ActionChoices.publicSaleFailed,
            "not publicSaleFailed status"
        );
    
        require(tokenIdList.length <= maxNftAMOUNT, "tokenIdList lenght >= 10");
        for (uint i = 0; i < tokenIdList.length; i++) {
            require(
                receiptNFT.ownerOf(tokenIdList[i]) == _msgSender(),
                "Insufficient Owner"
            );
            publicSaleTotalSold -= 1;
            receiptNFT.burn(tokenIdList[i]);
            emit redeemPublicSaleLog(tokenIdList[i], shareType.firstSharePrice);
        }
        usdt.safeTransfer(
            _msgSender(),
            tokenIdList.length * shareType.firstSharePrice
        );
    }

    //Receive the first construction fee
    function claimFirstBuildFee() public nonReentrant {
        require(platformAddr == _msgSender(), "permission denied");
        require(schedule == ActionChoices.startBuild, "not startBuild status");
        //First Fee
        usdt.safeTransfer(addrType.builderAddr, feeType.firstBuildFee);
        //Send money to the platform
        usdt.safeTransfer(platformFeeAddr, feeType.publicSalePlatformFee);
        //Hit the insurance premium
        usdt.safeTransfer(
            addrType.buildInsuranceAddr,
            feeType.buildInsuranceFee
        );
        //Hit the money
        emit buildInsuranceReceiveLog(
            addrType.buildInsuranceAddr,
            feeType.buildInsuranceFee,
            block.timestamp
        );
        schedule = ActionChoices.remainPayment;
        remainPaymentTime = block.timestamp + limitTimeType.startBuildLimitTime;

        emit claimFirstBuildFeeLog(
            addrType.builderAddr,
            feeType.firstBuildFee,
            block.timestamp
        );
    }

    //The user pays the final payment
    function remainPayment(uint256[] memory tokenIdList) public nonReentrant {
        require(
            schedule == ActionChoices.remainPayment,
            "not remainPayment status"
        );
        require(issuedTotalShare < shareType.financingShare, "Sold out");
        //Cannot be less than zero
        require(
            (remainPaymentTime + limitTimeType.remainPaymentLimitTime) >
                block.timestamp &&
                block.timestamp > remainPaymentTime,
            "time expired"
        );

        for (uint i = 0; i < tokenIdList.length; i++) {
            require(
                receiptNFT.ownerOf(tokenIdList[i]) == _msgSender(),
                "Insufficient balance"
            ); //Not an NFT owner
            issuedTotalShare += 1;
            receiptNFT.burn(tokenIdList[i]);
        }

        shareNFT.mint(_msgSender(), tokenIdList.length);
        usdt.safeTransferFrom(
            _msgSender(),
            address(this),
            tokenIdList.length * shareType.remainSharePrice
        );
        emit remainPaymentLog(
            _msgSender(),
            tokenIdList.length,
            shareType.remainSharePrice,
            block.timestamp
        );
        _whetherFinish();
    }

    //Check if it's done
    function _whetherFinish() private {
        if (issuedTotalShare >= shareType.financingShare) {
            shareNFT.mint(platformFeeAddr, shareType.platformShare);
            shareNFT.mint(founderAddr, shareType.founderShare);
            schedule = ActionChoices.FINISH;
            emit whetherFinishLog(true, block.timestamp);
        }
    }

    //Check whether the final payment is successful
    function checkRemainPayment() public nonReentrant {
        require(
            schedule == ActionChoices.remainPayment,
            "not remainPayment status"
        );

        if (
            (remainPaymentTime + limitTimeType.remainPaymentLimitTime) >
            block.timestamp
        ) {
            if (issuedTotalShare >= shareType.financingShare) {
                _whetherFinish();
            }
        } else {
            if (issuedTotalShare < shareType.financingShare) {
                bargainTime = block.timestamp;
                schedule = ActionChoices.Bargain;
                receiptNFT.pause();
                emit startBargainLog(
                    shareType.financingShare - issuedTotalShare,
                    block.timestamp
                );
            }
        }
    }

    //Pick up leaks
    function remainBargain(uint256 amount_) public nonReentrant {
        require(schedule == ActionChoices.Bargain, "not PAID status");
        require(issuedTotalShare < shareType.financingShare, "Sold out");
        require(
            amount_ <= maxNftAMOUNT && amount_ > 0,
            "amount Limit Exceeded"
        );
        //Cannot be less than zero
        require(
            bargainTime + limitTimeType.bargainLimitTime > block.timestamp,
            "time expired"
        );
        //Insufficient balance
        uint256 balance = shareType.financingShare - issuedTotalShare;
        require(balance > 0, "Sold out");
        if (amount_ > balance) {
            amount_ = balance;
        }
        issuedTotalShare += amount_;
        shareNFT.mint(_msgSender(), amount_);
        usdt.safeTransferFrom(
            _msgSender(),
            address(this),
            amount_ * shareType.remainSharePrice
        );
        _whetherFinish();
        emit remainBargainLog(
            _msgSender(),
            amount_,
            amount_ * shareType.remainSharePrice,
            block.timestamp
        );
    }

    //Check for leaks
    function checkBargain() public nonReentrant {
        require(schedule == ActionChoices.Bargain, "not PAID status");
        //Cannot be less than zero
        require(
            bargainTime + limitTimeType.bargainLimitTime > block.timestamp,
            "RemainPayment time is not up"
        );

        if (issuedTotalShare < shareType.financingShare) {
            schedule = ActionChoices.FAILED;
            emit whetherFinishLog(false, block.timestamp);
        } else {
            _whetherFinish();
        }
    }

    //Redemption of equity payments
    function redeemRemainPayment(
        uint256[] memory tokenIdList
    ) public nonReentrant {
        require(schedule == ActionChoices.FAILED, "not FAILED status");
        require(
            tokenIdList.length <= 10 && tokenIdList.length > 0,
            "not FAILED status"
        );
        for (uint i = 0; i < tokenIdList.length; i++) {
            require(
                receiptNFT.ownerOf(tokenIdList[i]) == _msgSender(),
                "Insufficient owner"
            );
            //Check your balance
            receiptNFT.burn(tokenIdList[i]);
            issuedTotalShare--;
            //Hit the money
            emit redeemRemainPaymentLog(
                tokenIdList[i],
                shareType.remainSharePrice
            );
        }
        usdt.safeTransfer(
            _msgSender(),
            shareType.remainSharePrice * tokenIdList.length
        );
    }

    //Receive the remaining payment
    function claimRemainBuildFee() public nonReentrant {
        require(_msgSender() == addrType.builderAddr, "permission denied");
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        require(isClaimRemainBuild == false, "Can not receive repeatedly"); //It cannot be claimed repeatedly
        usdt.safeTransfer(addrType.builderAddr, feeType.remainBuildFee);
        usdt.safeTransfer(platformFeeAddr, feeType.publicSalePlatformFee);
        isClaimRemainBuild = true;
        operationStartTime = block.timestamp;
        electrStartTime = block.timestamp;
        emit claimRemainBuildFeeLog(
            addrType.builderAddr,
            feeType.remainBuildFee,
            block.timestamp
        );
    }

    function checkDone() public nonReentrant {
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        require(dividends == address(0), "contract had deployed!");
        spvStartTime = block.timestamp;
        trustStartTime = block.timestamp;
        insuranceStartTime = block.timestamp;
        dividends = deployDividends();
        if (isClaimRemainBuild) {
            usdt.safeTransfer(dividends, usdt.balanceOf(address(this)));
        } else {
            uint256 amout = usdt.balanceOf(address(this)) -
                feeType.remainBuildFee -
                feeType.publicSalePlatformFee;
            usdt.safeTransfer(dividends, amout);
        }
    }
}
