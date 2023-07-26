// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./NFT721Impl.sol";

//interface IBidding { tender.sol
interface IBidding {
    //  查看用户状态            // 返回 数量, 状态,
    function viewSubscribe(address) external view returns (uint256);

    function transferAmount(uint256 amount) external;
}

// 股权融资
contract Financing is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public saleIsActive;

    //type(UniswapV2Pair).creationCode;
    // bytes public BYTECODE = type(NFT721Impl).creationCode;

    IERC20 public usdt;
    NFT721Impl public receiptNFT; // 股权  equityNFT
    NFT721Impl public shareNFT; // 股权  equityNFT
    IBidding public bidding; // 股权  equityNFT

    uint256 public constant maxNftAMOUNT = 10;

    // 电力质押时间
    bool public electrStakeLock;
    bool public isClaimRemainBuild; // 是否

    enum ActionChoices {
        INIT,
        whitelistPayment, // 白名单
        publicSale, // 公售
        publicSaleFailed, // 公售失败
        startBuild, // 开始建造
        remainPayment, // 尾款
        Bargain, // 捡漏
        FINISH, // 完成
        FAILED // 失败
    }

    ActionChoices public schedule;

    struct AddrType {
        address builderAddr; // 建造人
        address buildInsuranceAddr; // 建造保险地址
        address insuranceAddr; // 保险提供方
        address operationsAddr; // 运维提供方
        address spvAddr; // SPV地址
        address electrStakeAddr; // 电力质押地址
        address electrAddr; // 电力人
    }

    AddrType public addrType;

    mapping(address => bool) public paidUser; // 实缴用户

    LimitTimeType public limitTimeType;

    address public platformAddr; //平台管理地址
    address public platformFeeAddr; //平台收款地址
    address public founderAddr; // 创始人

    uint256 public issuedTotalShare; //  发行总股数
    uint256 public publicSaleTotalSold; //  第一阶段总数量

    uint256 public whitelistPaymentTime; // 白名单开始时间
    uint256 publicSaleTime; // 公售开始时间
    uint256 startBuildTime; //  开始建造时间
    uint256 bargainTime; // 捡漏开始时间
    uint256 remainPaymentTime; // 白名单开始时间

    uint256 electrStartTime; // 上次电力结算时间
    uint256 operationStartTime; // 上次运维结算时间
    uint256 insuranceStartTime; // 上保险次结算时间
    uint256 spvStartTime; // 上保险次结算时间

    //    feeInfo[]   public  feeList; 无效
    struct FeeType {
        uint256 firstBuildFee; //首次建造款
        uint256 remainBuildFee; //剩余建造款
        uint256 operationsFee; //运费费
        uint256 electrFee; // 电费
        uint256 electrStakeFee; // 质押电费
        uint256 buildInsuranceFee; // 建造保险费
        uint256 insuranceFee; // 保修费
        uint256 spvFee; // 信托管理费
        uint256 publicSalePlatformFee; // 公售平台费
        uint256 remainPlatformFee; // 公售平台费
    }
    FeeType public feeType;

    //  限时 limit  间隔 Interval
    struct LimitTimeType {
        uint256 whitelistPaymentLimitTime; // 白名单限时
        uint256 publicSaleLimitTime; // 公售限时
        uint256 startBuildLimitTime; // 开始建造时间
        uint256 bargainLimitTime; // 捡漏开始时间
        uint256 remainPaymentLimitTime; // 白名单开始时间
        uint256 electrIntervalTime; // 电力间隔时间
        uint256 operationIntervalTime; // 运维间隔时间
        uint256 insuranceIntervalTime; // 保险次结算时间
        uint256 spvIntervalTime; // 信托间隔时间
    }

    struct ShareType {
        uint256 totalShare; // 总股数
        uint256 financingShare; // 融资融资股
        uint256 founderShare; // 创始人股数
        uint256 platformShare; // 平台股数
        uint256 sharePrice; // 股价
        uint256 stakeSharePrice; // 质押股价
        uint256 firstSharePrice; // 首次股价
        uint256 remainSharePrice; // 补缴股价
    }

    ShareType public shareType;

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

    event energyReceiveLog(address, uint256 amount_, uint256 time_);
    event startPublicSaleLog(uint256 unpaid_, uint256 time_);
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
    event whetherFirstPaymentFinishLog(bool, uint256 time_); // 是否     完成
    event whetherFinishLog(bool, uint256 time_); // 是否 完成

    constructor(
        IERC20 usdtAddr_,
        IBidding bidding_, //  招投标合约
        address platformFeeAddr_,
        address founderAddr_,
        FeeType memory feeList_, // fees
        AddrType memory addrList_, // address  集合 //TODO check
        LimitTimeType memory limitTimeList_, // times  集合 //TODO check
        ShareType memory shareList_, // Share  集合 //TODO check
        string memory uri_1,
        string memory uri_2
    ) {
        //        grantRole(MINTER_ROLE, _msgSender());

        whitelistPaymentTime = block.timestamp;

        saleIsActive = false;

        shareType = shareList_;
        addrType = addrList_;
        limitTimeType = limitTimeList_;
        feeType = feeList_;

        // feeList_ field check
        require(feeList_.firstBuildFee != 0, "firstBuildFee == 0"); //首次建造款
        require(feeList_.remainBuildFee != 0, "remainBuildFee == 0"); //剩余建造款
        require(feeList_.operationsFee != 0, "operationsFee == 0"); //运费费
        require(feeList_.electrFee != 0, "electrFee== 0"); // 电费
        require(feeList_.electrStakeFee != 0, "electrStakeFee == 0"); // 质押电费
        require(feeList_.buildInsuranceFee != 0, "buildInsuranceFee == 0"); // 建造保险费
        require(feeList_.insuranceFee != 0, "insuranceFee == 0"); // 保修费
        require(feeList_.spvFee != 0, "spvFee== 0"); // 信托管理费
        // require(
        //     feeList_.length == uint256(feeType.remainPlatformFee),
        //     "feeList_  Insufficient number of parameters"
        // ); // 参数数量不足

        // require(
        //     addrList_.length == uint256(addrType.electrAddr),
        //     "addrList_ Insufficient number of parameters"
        // ); // 参数数量不足
        // require(
        //     limitTimeList_.length == uint256(limitTimeType.spvIntervalTime),
        //     "Insufficient number of parameters"
        // ); // 参数数量不足
        // require(
        //     shareList_.length == uint256(shareType.remainSharePrice),
        //     "Insufficient number of parameters"
        // ); // 参数数量不足
        require(address(usdtAddr_) != address(0), "usdt Can not be empty");
        require(
            platformFeeAddr_ != address(0),
            "platformFeeAddr_ Can not be empty"
        );

        platformAddr = _msgSender(); //平台管理地址
        platformFeeAddr = platformFeeAddr_; //平台收款地址

        founderAddr = founderAddr_;
        // for (uint i = 1; i < feeList_.length; i++) {
        //     feeType(i)] = feeList_[i;
        // }
        // for (uint i = 1; i < addrList_.length; i++) {
        //     require(addrList_[i] != address(0), "address not zero");
        //     addrType(i) = addrList_[i];
        // }

        // for (uint i = 1; i < limitTimeList_.length; i++) {
        //     limitTimeType(i)] = limitTimeList_[i;
        // }

        // for (uint i = 1; i < shareList_.length; i++) {
        //     shareType(i)] = shareList_[i;
        // }
        require(
            shareType.sharePrice ==
                shareType.stakeSharePrice +
                    shareType.firstSharePrice +
                    shareType.remainSharePrice,
            "sharePrice verification failed"
        ); // 价格校验失败
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

    function deployNFT(
        string memory name_,
        string memory symbol_
    ) public returns (address) {
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

    //  白名单支付
    function whiteListPayment() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.whitelistPayment, "not PAID status");
        require(shareType.financingShare > publicSaleTotalSold, "sold out");
        require(!paidUser[_msgSender()], " Cannot participate repeatedly"); //  不能重复参与

        paidUser[_msgSender()] = true;
        //  不能小于零
        require(
            whitelistPaymentTime + limitTimeType.publicSaleLimitTime >
                block.timestamp,
            "time expired"
        );

        //  查看招投标合约用户质押状态 数量, 状态,
        uint256 amount = bidding.viewSubscribe(_msgSender());

        // 必须为锁定状态
        require(amount > 0, "Not yet subscribed");
        // 数量 大于0
        if (shareType.financingShare - publicSaleTotalSold < amount) {
            amount = shareType.financingShare - publicSaleTotalSold;
        }
        publicSaleTotalSold += amount;

        //TODO
        // uint256 gAmout = amount * shareType.stakeSharePrice;
        // bidding.transferAmount(gAmout);

        // 同时通知招投标合约释放押金
        usdt.safeTransferFrom(
            _msgSender(),
            address(this),
            amount * (shareType.firstSharePrice - shareType.stakeSharePrice)
        );

        emit whiteListPaymentLog(
            _msgSender(),
            amount,
            shareType.firstSharePrice,
            block.timestamp
        );

        // 铸造凭证 nft
        receiptNFT.mint(_msgSender(), amount);
        _whetherFirstPaymentFinish();
    }

    //  检查首付是否完成
    function _whetherFirstPaymentFinish() private {
        if (publicSaleTotalSold >= shareType.financingShare) {
            startBuildTime = block.timestamp;
            schedule = ActionChoices.startBuild;
            emit whetherFirstPaymentFinishLog(true, block.timestamp);
        }
    }

    // 检查第一次实缴是否成功
    function checkWhiteList() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
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

    // 公售
    // @param amount_股数
    function publicSale(uint256 amount_) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.publicSale, "not PAID status");
        require(
            amount_ <= maxNftAMOUNT && amount_ > 0,
            "amount Limit Exceeded"
        ); // 超出限制
        // 判断状态
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
        uint256 mAmount = amount_ *
            (shareType.firstSharePrice - shareType.stakeSharePrice);

        uint256 gAmout = amount_ * shareType.stakeSharePrice;

        bidding.transferAmount(gAmout);

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

    // 检查公售
    function checkPublicSale() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.publicSale, "not PAID status");
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

    // 退回公售
    function redeemPublicSale(uint256[] memory tokenIdList) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(
            schedule == ActionChoices.publicSaleFailed,
            "not publicSaleFailed status"
        );
        require(tokenIdList.length <= maxNftAMOUNT, "tokenIdList lenght >= 10");

        for (uint i = 0; i < tokenIdList.length; i++) {
            require(
                receiptNFT.ownerOf(tokenIdList[i]) == _msgSender(),
                "Insufficient balance"
            ); // 不是nft  所有者

            issuedTotalShare -= 1;
            receiptNFT.burn(tokenIdList[i]);
            usdt.safeTransferFrom(
                _msgSender(),
                address(this),
                shareType.remainSharePrice
            );

            emit redeemPublicSaleLog(
                tokenIdList[i],
                shareType.firstSharePrice + shareType.stakeSharePrice
            );
        }

        usdt.safeTransfer(
            _msgSender(),
            tokenIdList.length * shareType.firstSharePrice
        );
    }

    // 领取首次建造费
    function claimFirstBuildFee() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(addrType.builderAddr == _msgSender(), "permission denied");
        //
        require(schedule == ActionChoices.startBuild, "not startBuild status");

        // 首次费用
        usdt.safeTransfer(addrType.builderAddr, feeType.firstBuildFee);
        // 给平台打钱
        usdt.safeTransfer(platformFeeAddr, feeType.publicSalePlatformFee);
        // 打保险费
        usdt.safeTransfer(
            addrType.buildInsuranceAddr,
            feeType.buildInsuranceFee
        );
        // 打钱
        emit buildInsuranceReceiveLog(
            addrType.buildInsuranceAddr,
            feeType.buildInsuranceFee,
            block.timestamp
        );
        schedule == ActionChoices.remainPayment;
        remainPaymentTime = block.timestamp + limitTimeType.startBuildLimitTime;

        emit claimFirstBuildFeeLog(
            addrType.builderAddr,
            feeType.firstBuildFee,
            block.timestamp
        );
    }

    // 用户付尾款
    function remainPayment(uint256[] memory tokenIdList) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(
            schedule == ActionChoices.remainPayment,
            "not remainPayment status"
        );
        require(issuedTotalShare < shareType.financingShare, "Sold out");
        //  不能小于零
        require(
            remainPaymentTime + limitTimeType.remainPaymentLimitTime >
                block.timestamp &&
                block.timestamp > remainPaymentTime,
            "time expired"
        );

        for (uint i = 0; i < tokenIdList.length; i++) {
            require(
                receiptNFT.ownerOf(tokenIdList[i]) == _msgSender(),
                "Insufficient balance"
            ); // 不是nft  所有者
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

    //  检查是否完成
    function _whetherFinish() private {
        if (issuedTotalShare >= shareType.financingShare) {
            shareNFT.mint(platformFeeAddr, shareType.platformShare);
            shareNFT.mint(founderAddr, shareType.founderShare);
            schedule = ActionChoices.FINISH;
            emit whetherFinishLog(true, block.timestamp);
        }
    }

    // 检查尾款是否成功
    function checkRemainPayment() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.remainPayment, "not PAID status");

        require(
            remainPaymentTime + limitTimeType.remainPaymentLimitTime >
                block.timestamp,
            "RemainPayment time is not up"
        ); // 时间未到
        // 时间到期

        if (issuedTotalShare < shareType.financingShare) {
            bargainTime = block.timestamp;
            schedule = ActionChoices.Bargain;
            //TODO
            //NFT.tokenIdBurn(receiptToken);
            emit whetherFinishLog(false, block.timestamp);
        } else {
            _whetherFinish();
        }
    }

    // 捡漏
    function remainBargain(uint256 amount_) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.Bargain, "not PAID status");
        require(issuedTotalShare < shareType.financingShare, "Sold out");
        require(
            amount_ <= maxNftAMOUNT && amount_ > 0,
            "amount Limit Exceeded"
        );

        //  不能小于零
        require(
            bargainTime + limitTimeType.bargainLimitTime > block.timestamp,
            "time expired"
        );

        // 余额不足
        uint256 balance = shareType.financingShare - issuedTotalShare;
        require(balance <= 0, "Sold out");
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

    // 检查捡漏
    function checkBargain() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.Bargain, "not PAID status");

        //  不能小于零
        require(
            bargainTime + limitTimeType.bargainLimitTime > block.timestamp,
            "RemainPayment time is not up"
        ); // 时间未到
        // 时间到期
        if (issuedTotalShare < shareType.financingShare) {
            schedule = ActionChoices.FAILED;
            emit whetherFinishLog(false, block.timestamp);
        } else {
            _whetherFinish();
        }
    }

    // 赎回股权付款
    function redeemRemainPayment(uint256[] memory tokenIdList) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.FAILED, "not FAILED status");
        require(
            tokenIdList.length <= 10 && tokenIdList.length > 0,
            "not FAILED status"
        );
        for (uint i = 0; i < tokenIdList.length; i++) {
            require(
                receiptNFT.ownerOf(tokenIdList[i]) == _msgSender(),
                "Insufficient balance"
            ); // 不是nft  所有者
            // 查看余额
            receiptNFT.burn(tokenIdList[i]);

            // 打钱
            emit redeemRemainPaymentLog(
                tokenIdList[i],
                shareType.remainSharePrice
            );
        }
        usdt.safeTransfer(_msgSender(), shareType.remainSharePrice);
    }

    // 领取剩余的货款
    function claimRemainBuildFee() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(_msgSender() == addrType.builderAddr, "permission denied");
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        require(isClaimRemainBuild == false, "Can not receive repeatedly"); //  不能能重复领取

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

    // 运维 领取 30天一次
    function operationsReceive() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(
            _msgSender() == addrType.operationsAddr,
            "user does not have permission"
        );
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        require(
            operationStartTime + limitTimeType.operationIntervalTime <
                block.timestamp,
            "Refusal to contract transactions"
        );

        // 判断第一次领取 需要质押电力 // 3000
        uint256 months = block.timestamp -
            (operationStartTime + limitTimeType.operationIntervalTime) /
            limitTimeType.operationIntervalTime;

        uint256 amount = months * feeType.operationsFee;
        operationStartTime += months * limitTimeType.operationIntervalTime;
        usdt.safeTransfer(addrType.operationsAddr, amount);

        emit operationsReceiveLog(_msgSender(), amount, block.timestamp);
    }

    //  spv 领取
    function spvReceive() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(
            _msgSender() == addrType.spvAddr,
            "user does not have permission"
        );
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        // 判断状态
        uint256 amount;
        if (spvStartTime == 0) {
            amount = feeType.spvFee;
            usdt.safeTransfer(addrType.spvAddr, amount);
            spvStartTime = block.timestamp;
        } else {
            require(
                spvStartTime + limitTimeType.spvIntervalTime < block.timestamp,
                "Refusal to contract transactions"
            );
            uint256 year = (block.timestamp - spvStartTime) /
                limitTimeType.spvIntervalTime;

            amount = year * feeType.spvFee;
            spvStartTime += year * limitTimeType.spvIntervalTime;
            usdt.safeTransfer(addrType.spvAddr, amount);
        }

        emit spvReceiveLog(addrType.spvAddr, amount, block.timestamp);
    }

    //  押金
    function electrStake() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(
            _msgSender() == addrType.electrStakeAddr,
            "user does not have permission"
        );
        // 用户没有权限
        require(schedule == ActionChoices.FINISH, "not RUNNING status");
        require(electrStakeLock == false, "not FINISH status");
        // 判断第一次领取 需要质押电力  todo 时间计算公式
        electrStakeLock = true;
        usdt.safeTransfer(addrType.electrStakeAddr, feeType.electrStakeFee);

        emit electrStakeLog(
            addrType.electrStakeAddr,
            feeType.electrStakeFee,
            block.timestamp
        );
    }

    // 电力领取  30天一次
    function energyReceive() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(
            _msgSender() == addrType.electrAddr,
            "user does not have permission"
        );
        // 用户没有权限
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        require(
            electrStartTime + limitTimeType.electrIntervalTime <
                block.timestamp,
            "Refusal to contract transactions"
        );
        // 判断第一次领取 需要质押电力
        uint256 months = block.timestamp -
            electrStartTime /
            limitTimeType.electrIntervalTime;

        uint256 amount = months * feeType.electrFee;
        electrStartTime += months * limitTimeType.electrIntervalTime;
        // 判断第一次押金
        usdt.safeTransfer(addrType.electrAddr, amount);
        emit energyReceiveLog(addrType.electrAddr, amount, block.timestamp);
    }

    // 保险领取  一年一次
    function insuranceReceive() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        // 拒绝合约交易
        require(
            _msgSender() == addrType.insuranceAddr,
            "user does not have permission"
        );
        // 不能
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        uint256 amount;
        if (insuranceStartTime == 0) {
            amount = feeType.insuranceFee;
            usdt.safeTransfer(addrType.insuranceAddr, amount);
            insuranceStartTime = block.timestamp;
        } else {
            require(
                insuranceStartTime + limitTimeType.insuranceIntervalTime <
                    block.timestamp,
                "Refusal to contract transactions"
            );
            uint256 year = (block.timestamp - insuranceStartTime) /
                limitTimeType.insuranceIntervalTime;

            amount = year * feeType.insuranceFee;
            insuranceStartTime += year * limitTimeType.insuranceIntervalTime;
            usdt.safeTransfer(addrType.insuranceAddr, amount);
        }

        emit insuranceReceiveLog(
            addrType.insuranceAddr,
            amount,
            block.timestamp
        );
    }

    // 分红规则投票
    function dividends() public whenNotPaused nonReentrant {
        //        分红类提案参数：（存在分红投票提案是，不允许新的分红提案出现）
        //        1.分红时间（投票”7天投票时间“后即可执行）；
        //        2.分红资产：可分红资产(计算公式如下）
        //        3.分红地址：全体token持有人
        //        4.判断执行与否：同意>不同意 即可执行， 同意<不同意，即不执行
        //
        //        可分红资产=当前合约资产-历史总未领取分红资产-下一阶段应付电费费用（应付电费/当前WBTC/USDT价格）-下一阶段应付运维费用（应付运维费/当前Wbtc/USDT价格）
    }

    // 项目失败后撤资
    function failDivestment() public whenNotPaused nonReentrant {}

    function getChoice() public view returns (ActionChoices) {
        return schedule;
    }
}
