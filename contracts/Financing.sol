// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./lib/IERC1155S.sol";

//interface IBidding { tender.sol
interface IBidding {
    //  查看用户状态            // 返回 数量, 状态,
    function viewSubscribe(address) external view returns (uint256);
}



// 股权融资
contract financing is AccessControl,Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public saleIsActive;

    IERC20 public usdt;
    IERC1155S public  NFT;  // 股权  equityNFT
    IBidding public  bidding;  // 股权  equityNFT

    uint256 constant receiptToken = 1;
    uint256 constant shareToken = 2;

    // 电力质押时间
    bool public electrStakeLock;
    bool public isClaimRemainBuild;   // 是否

    enum ActionChoices {
        INIT,
        whitelistPayment,  // 白名单
        publicSale,   // 公售
        publicSaleFailed,  // 公售失败
        startBuild,   // 开始建造
        remainPayment,   // 尾款
        Bargain,    // 捡漏
        FINISH,   // 完成
        FAILED    // 失败
    }

    ActionChoices schedule;


    enum addrType {
        invalid,
        builderAddr,         // 建造人
        buildInsuranceAddr,  // 建造保险地址
        insuranceAddr,       // 保险提供方
        operationsAddr,      // 运维提供方
        spvAddr,             // SPV地址
        electrStakeAddr,     // 电力质押地址
        electrAddr           // 电力人
    }
    mapping(addrType => address) public  addrList;
    mapping(address => uint256) public paidUser ;  // 实缴用户
    mapping(limitTimeType => uint256) public  limitTimeList;


    address public platformAddr;        //平台管理地址
    address public platformFeeAddr;     //平台收款地址
    address public founderAddr;        // 创始人

    uint256 public issuedTotalShare;            //  发行总股数
    uint256 public publicSaleTotalSold;         //  第一阶段总数量



    uint256  whitelistPaymentTime;  // 白名单开始时间
    uint256  publicSaleTime;        // 公售开始时间
    uint256  startBuildTime;        //  开始建造时间
    uint256  bargainTime;           // 捡漏开始时间
    uint256  remainPaymentTime;     // 白名单开始时间

    uint256  electrStartTime;       // 上次电力结算时间
    uint256  operationStartTime;    // 上次运维结算时间
    uint256  insuranceStartTime;    // 上保险次结算时间
    uint256  spvStartTime;          // 上保险次结算时间


    //    feeInfo[]   public  feeList; 无效
    enum feeType {
        invalid,
        firstBuildFee,   //首次建造款
        remainBuildFee,  //剩余建造款
        operationsFee,   //运费费
        electrFee,       // 电费
        electrStakeFee,  // 质押电费
        buildInsuranceFee,  // 建造保险费
        insuranceFee,     // 保修费
        spvFee,    // 信托管理费
        publicSalePlatformFee,  // 公售平台费
        remainPlatformFee  // 公售平台费
    }
    mapping(feeType => uint256) public feeList;

    //  限时 limit  间隔 Interval
    enum limitTimeType {
        invalid,
        whitelistPaymentLimitTime,  // 白名单限时
        publicSaleLimitTime,        // 公售限时
        startBuildLimitTime,        // 开始建造时间
        bargainLimitTime,           // 捡漏开始时间
        remainPaymentLimitTime,     // 白名单开始时间
        electrIntervalTime,         // 电力间隔时间
        operationIntervalTime,      // 运维间隔时间
        insuranceIntervalTime,      // 保险次结算时间
        spvIntervalTime             // 信托间隔时间
    }



    enum shareType {
        invalid,
        totalShare,            // 总股数
        financingShare,        // 融资融资股
        founderShare,          // 创始人股数
        platformShare,         // 平台股数

        sharePrice,            // 股价
        stakeSharePrice,       // 质押股价
        firstSharePrice,       // 首次股价
        remainSharePrice       // 补缴股价
    }

    mapping(shareType => uint256) public  shareList;


    event claimFirstBuildFeeLog(address energyAddr_, uint256 firstFee_, uint256 receiveTime_);
    event claimRemainBuildFeeLog(address energyAddr_, uint256 firstFee_,  uint256 receiveTime_);

    event buildInsuranceReceiveLog(address addr_, uint256 amount_, uint256 time_);
    event operationsReceiveLog(address addr_, uint256 amount_, uint256 time_);
    event spvReceiveLog(address addr_, uint256 amount_, uint256 time_);
    event electrStakeLog(address feeAddr, uint256 amount,uint256 time_);
    event redeemRemainPaymentLog(uint256 tokenId_, uint256 balance_, uint256 amount_);
    event remainBargainLog(address account_, uint256 balance_, uint256 price_, uint256 time_);
    event remainPaymentLog(address account_, uint256 amount_, uint256 sharePrice, uint256 tokenId_, uint256 time_);
    event whiteListPaymentLog(address account_, uint256 tokenId_, uint256 amount_, uint256 price_, uint256 time_);
    event redeemPublicSaleLog(uint256 tokenId_, uint256 balance_, uint256 amount_);

    event energyReceiveLog(address,uint256 amount_, uint256 time_);
    event startPublicSaleLog(uint256 unpaid_, uint256 time_);
    event publicSaleLog(address,  uint256 amount_,  uint256 price_,uint256 time_ );
    event checkPublicSaleLog(uint256 time_, ActionChoices);
    event checkRemainPaymentLog(uint256 tokenId, uint256 time_);
    event insuranceReceiveLog(address energyAddr_, uint256 amount_,  uint256 time_);
    event whetherFirstPaymentFinishLog( bool,  uint256 time_);  // 是否     完成
    event whetherFinishLog( bool,  uint256 time_);  // 是否 完成





    constructor(
        IERC20 usdtAddr_,
        IBidding bidding_,     //  招投标合约
        address platformFeeAddr_,
        address founderAddr_,
        uint256[] memory feeList_,  // fees
        address[] memory addrList_, // address  集合
        uint256[] memory limitTimeList_,  // times  集合
        uint256[] memory shareList_  // Share  集合

    ){

        //        grantRole(MINTER_ROLE, _msgSender());

        saleIsActive = false;


        require(feeList_.length == uint256(feeType.remainPlatformFee), "feeList_  Insufficient number of parameters");  // 参数数量不足

        require(addrList_.length == uint256(addrType.electrAddr), "addrList_ Insufficient number of parameters");  // 参数数量不足
        require(limitTimeList_.length ==   uint256(limitTimeType.spvIntervalTime), "Insufficient number of parameters");  // 参数数量不足
        require(shareList_.length ==   uint256(shareType.remainSharePrice), "Insufficient number of parameters");  // 参数数量不足
        require(address(usdtAddr_) != address(0), "usdt Can not be empty");
        require(platformFeeAddr_ != address(0), "platformFeeAddr_ Can not be empty");


        platformAddr = _msgSender();        //平台管理地址
        platformFeeAddr = platformFeeAddr_;     //平台收款地址

        founderAddr = founderAddr_;
        for (uint i = 1; i< feeList_.length; i++  ) {
            feeList[feeType(i)] = feeList_[i];
        }
        for (uint i = 1; i< addrList_.length; i++  ) {
            require(addrList_[i] !=  address(0), "address not zero");
            addrList[addrType(i)] = addrList_[i];
        }

        for (uint i = 1; i< limitTimeList_.length; i++  ) {
            limitTimeList[limitTimeType(i)] = limitTimeList_[i];
        }


        for (uint i = 1; i< shareList_.length; i++  ) {
            shareList[shareType(i)] = shareList_[i];
        }
        require(
            shareList[shareType. sharePrice] ==
            shareList[shareType.stakeSharePrice] +shareList[shareType.firstSharePrice] +shareList[shareType. remainSharePrice],
            "sharePrice verification failed");   // 价格校验失败
        require(
            shareList[shareType.totalShare ] ==
            shareList[shareType.financingShare] +shareList[shareType.founderShare] +shareList[shareType. platformShare],
            "share verification failed");



        bidding =bidding_;
        usdt = usdtAddr_;
        schedule = ActionChoices.INIT;
    }


    // 设置NFT
    function SetNft( IERC1155S NFTAddr_) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(_msgSender() == platformAddr, "permission denied");
        require(schedule == ActionChoices.INIT, "not PAID status");
        require(address(NFTAddr_) != address(0), "NFT Can not be empty");
        NFT = NFTAddr_;
        whitelistPaymentTime = block.timestamp;
        schedule = ActionChoices.whitelistPayment;
    }

    //  白名单支付
    function whiteListPayment() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.whitelistPayment, "not PAID status");
        require(shareList[shareType.financingShare] >  publicSaleTotalSold, "sold out");
        require(paidUser[_msgSender()]  > 0, " Cannot participate repeatedly");  //  不能重复参与


        //  不能小于零
        require(whitelistPaymentTime + limitTimeList[limitTimeType.publicSaleLimitTime] > block.timestamp, "time expired");


        //  查看招投标合约用户质押状态 数量, 状态,
        uint256 amount = bidding.viewSubscribe(_msgSender());
        // 必须为锁定状态
        require(amount > 0, "Not yet subscribed");
        // 数量 大于0
        if (shareList[shareType.financingShare]  - publicSaleTotalSold < amount) {
            amount = shareList[shareType.financingShare]  - publicSaleTotalSold;
        }
        publicSaleTotalSold += amount;
        // 同时通知招投标合约释放押金
        usdt.safeTransferFrom(_msgSender(), address(this), amount *  shareList[shareType.firstSharePrice] );

        emit whiteListPaymentLog(_msgSender(), receiptToken, amount, shareList[shareType.firstSharePrice], block.timestamp);


        // 铸造凭证 nft
        NFT.mint(_msgSender(), receiptToken, amount);
        _whetherFirstPaymentFinish();
    }

    //  检查首付是否完成
    function  _whetherFirstPaymentFinish() private {
        if (publicSaleTotalSold >=  shareList[shareType.financingShare] ) {
            startBuildTime = block.timestamp;
            schedule = ActionChoices.startBuild;
            emit  whetherFirstPaymentFinishLog(true, block.timestamp);
        }
    }



    // 检查第一次实缴是否成功
    function checkWhiteList() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.whitelistPayment, "not PAID status");

        require(whitelistPaymentTime + limitTimeList[limitTimeType.whitelistPaymentLimitTime] < block.timestamp && whitelistPaymentTime != 0 , "time expired");

        if ( publicSaleTotalSold <  shareList[shareType.financingShare]) {

            uint256 unpaid = shareList[shareType.financingShare] - publicSaleTotalSold;
            schedule = ActionChoices.publicSale;
            emit startPublicSaleLog( unpaid, block.timestamp);
            publicSaleTime = block.timestamp;
        } else {
            _whetherFirstPaymentFinish();
        }
    }

    // 公售
    //TODO check 30%
    //TODO
    // @param amount_股数
    function publicSale(uint256 amount_) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.publicSale, "not PAID status");
        // 判断状态
        require(shareList[shareType.financingShare] > publicSaleTotalSold, "cannot be less than zero");

        require(publicSaleTime +limitTimeList[limitTimeType.publicSaleLimitTime] > block.timestamp, "time expired");
        require(amount_ > 0, "Not yet subscribed"); // 数量 大于0

        if (shareList[shareType.financingShare]  - publicSaleTotalSold< amount_) {
            amount_ = shareList[shareType.financingShare]  - publicSaleTotalSold;
        }
        publicSaleTotalSold += amount_;
        usdt.safeTransferFrom(_msgSender(), address(this), amount_ * shareList[shareType.firstSharePrice]);
        emit publicSaleLog(_msgSender(), amount_, amount_ * shareList[shareType.firstSharePrice], block.timestamp);


        // 铸造nft
        NFT.mint(_msgSender(), receiptToken, amount_);
        _whetherFirstPaymentFinish();
    }


    // 检查公售
    function checkPublicSale() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.publicSale, "not PAID status");
        require(publicSaleTime + limitTimeList[limitTimeType.publicSaleLimitTime] < block.timestamp, "time expired");

        if (shareList[shareType.financingShare] <= publicSaleTotalSold) {
            _whetherFirstPaymentFinish();
        } else {
            schedule = ActionChoices.publicSaleFailed;
            emit whetherFirstPaymentFinishLog(false, block.timestamp);
        }
    }



    // 退回公售
    function redeemPublicSale() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.publicSaleFailed, "not publicSaleFailed status");


        uint256 balance = NFT.balanceOf(_msgSender(), receiptToken);
        require(balance > 0, "Insufficient balance");
        // 查看余额
        // 铸造nft
        NFT.burn(_msgSender(), receiptToken, balance);
        // 铸造nft

        usdt.safeTransfer(_msgSender(), balance * (shareList[shareType.firstSharePrice] +shareList[shareType.stakeSharePrice]) );
        // 打钱

        emit redeemPublicSaleLog(receiptToken, balance,  balance * (shareList[shareType.firstSharePrice] +shareList[shareType.stakeSharePrice]) );
    }




    // 领取首次建造费
    function claimFirstBuildFee() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(addrList[addrType.builderAddr] == _msgSender(), "permission denied");
        //
        require(schedule == ActionChoices.startBuild, "not startBuild status");


        // 首次费用
        usdt.safeTransfer(addrList[addrType.builderAddr] , feeList[feeType.firstBuildFee]);
        // 给平台打钱
        usdt.safeTransfer(platformFeeAddr, feeList[feeType.publicSalePlatformFee]);
        // 打保险费
        usdt.safeTransfer(addrList[addrType.buildInsuranceAddr] , feeList[feeType.buildInsuranceFee]);
        // 打钱
        emit  buildInsuranceReceiveLog(addrList[addrType.buildInsuranceAddr]  , feeList[feeType.buildInsuranceFee],  block.timestamp);
        schedule == ActionChoices.remainPayment;
        remainPaymentTime = block.timestamp + limitTimeList[limitTimeType.startBuildLimitTime];

        emit claimFirstBuildFeeLog(addrList[addrType.builderAddr] , feeList[feeType.firstBuildFee],block.timestamp);

    }

    // 用户付尾款
    function remainPayment() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.remainPayment, "not remainPayment status");
        require( issuedTotalShare <  shareList[shareType.financingShare], "Sold out");
        //  不能小于零
        require(remainPaymentTime + limitTimeList[limitTimeType.remainPaymentLimitTime] > block.timestamp && block.timestamp > remainPaymentTime , "time expired");

        //  查询  nft  1155 余额并销毁
        uint256 balance = NFT.balanceOf(_msgSender(), receiptToken);
        //  发行同数量NFT
        require(balance > 0, "Insufficient receiptToken"); // 余额不足


        issuedTotalShare += balance;
        NFT.burn(_msgSender(), receiptToken, balance);
        NFT.mint(_msgSender(), shareToken, balance);
        usdt.safeTransferFrom(_msgSender(), address(this), balance * shareList[shareType.remainSharePrice]);

        emit remainPaymentLog(_msgSender(), balance, balance * shareList[shareType.remainSharePrice], shareToken, block.timestamp);

        _whetherFinish();

    }


    //  检查是否完成
    function _whetherFinish() private {
        if (issuedTotalShare >=  shareList[shareType.financingShare] ) {
            NFT.mint( platformFeeAddr, shareToken, shareList[shareType.platformShare]);
            NFT.mint( founderAddr, shareToken, shareList[shareType.founderShare]);
            schedule = ActionChoices.FINISH;
            emit  whetherFinishLog(true, block.timestamp);
        }
    }

    // 检查尾款是否成功
    function checkRemainPayment() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.remainPayment, "not PAID status");


        require(remainPaymentTime + limitTimeList[limitTimeType.remainPaymentLimitTime] > block.timestamp, "RemainPayment time is not up");  // 时间未到
        // 时间到期

        if (issuedTotalShare <   shareList[shareType.financingShare]) {
            bargainTime = block.timestamp;
            schedule  = ActionChoices.Bargain;
            //TODO
            //NFT.tokenIdBurn(receiptToken);
            emit whetherFinishLog(false, block.timestamp);
        } else {
            _whetherFinish();
        }

    }


    // 捡漏
    function remainBargain(uint256 amount_ ) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.Bargain, "not PAID status");
        require( issuedTotalShare <  shareList[shareType.financingShare], "Sold out");

        //  不能小于零
        require(bargainTime + limitTimeList[limitTimeType.bargainLimitTime] > block.timestamp, "time expired");

        // 余额不足
        uint256 balance = shareList[shareType.financingShare] - issuedTotalShare;

        if (amount_ > balance) {
            amount_ = balance;
        }
        issuedTotalShare += amount_;
        NFT.mint(_msgSender(), shareToken, amount_);
        usdt.safeTransferFrom(_msgSender(), address(this), amount_ * shareList[shareType.remainSharePrice]);

        _whetherFinish();
        emit remainBargainLog(_msgSender(), amount_, amount_ *  shareList[shareType.remainSharePrice], block.timestamp);
    }


    // 检查捡漏
    function checkBargain() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.Bargain, "not PAID status");

        //  不能小于零
        require(bargainTime + limitTimeList[limitTimeType.bargainLimitTime] > block.timestamp, "RemainPayment time is not up");  // 时间未到
        // 时间到期
        if (issuedTotalShare < shareList[shareType.financingShare]) {
            schedule= ActionChoices.FAILED;
            emit  whetherFinishLog(false, block.timestamp);
        } else {
            _whetherFinish();
        }
    }




    // 赎回股权付款
    function redeemRemainPayment() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(schedule == ActionChoices.FAILED, "not FAILED status");


        // 查看nft 资产
        uint256 balance = NFT.balanceOf(_msgSender(), shareToken);
        require(balance > 0, "Insufficient balance");
        // 查看余额
        // 铸造nft
        NFT.burn(_msgSender(), shareToken, balance);
        // 铸造nft
        usdt.safeTransfer(_msgSender(), balance * shareList[shareType.remainSharePrice]);
        // 打钱

        emit redeemRemainPaymentLog(shareToken, balance, balance * shareList[shareType.remainSharePrice]);
    }

    // 领取剩余的货款
    function claimRemainBuildFee() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(_msgSender() == addrList[addrType.builderAddr], "permission denied");
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        require(isClaimRemainBuild == false, "Can not receive repeatedly");  //  不能能重复领取

        usdt.safeTransfer(addrList[addrType.builderAddr] ,  feeList[feeType.remainBuildFee]);
        usdt.safeTransfer(platformFeeAddr,  feeList[feeType.publicSalePlatformFee]);


        isClaimRemainBuild = true;
        operationStartTime = block.timestamp;
        electrStartTime = block.timestamp;
        emit claimRemainBuildFeeLog(addrList[addrType.builderAddr] , feeList[feeType.remainBuildFee], block.timestamp);
    }




    // 运维 领取 30天一次
    function operationsReceive() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(_msgSender() == addrList[addrType.operationsAddr] , "user does not have permission");
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        require( operationStartTime + limitTimeList[limitTimeType.operationIntervalTime] < block.timestamp, "Refusal to contract transactions");

        // 判断第一次领取 需要质押电力 // 3000
        uint256 months = block.timestamp - (operationStartTime + limitTimeList[limitTimeType.operationIntervalTime]) / limitTimeList[limitTimeType.operationIntervalTime];

        uint256 amount = months *  feeList[feeType.operationsFee];
        operationStartTime += months * limitTimeList[limitTimeType.operationIntervalTime];
        usdt.safeTransfer(addrList[addrType.operationsAddr] , amount);

        emit operationsReceiveLog(_msgSender(), amount, block.timestamp);
    }



    //  spv 领取
    function spvReceive() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(_msgSender() == addrList[addrType.spvAddr] , "user does not have permission");
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        // 判断状态
        uint256 amount;
        if (spvStartTime == 0 )  {
            amount =  feeList[feeType.spvFee];
            usdt.safeTransfer(addrList[addrType.spvAddr] , amount);
            spvStartTime = block.timestamp;
        } else {
            require(spvStartTime + limitTimeList[limitTimeType.spvIntervalTime] < block.timestamp, "Refusal to contract transactions");
            uint256 year = (block.timestamp - spvStartTime) / limitTimeList[limitTimeType.spvIntervalTime];

            amount = year *  feeList[feeType.spvFee];
            spvStartTime += year * limitTimeList[limitTimeType.spvIntervalTime];
            usdt.safeTransfer(addrList[addrType.spvAddr] , amount);
        }

        emit spvReceiveLog(addrList[addrType.spvAddr] , amount, block.timestamp);
    }


    //  押金
    function electrStake() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(_msgSender() == addrList[addrType.electrStakeAddr] , "user does not have permission");
        // 用户没有权限
        require(schedule == ActionChoices.FINISH, "not RUNNING status");
        require(electrStakeLock == false, "not FINISH status");
        // 判断第一次领取 需要质押电力  todo 时间计算公式
        electrStakeLock = true;
        usdt.safeTransfer(addrList[addrType.electrStakeAddr] ,  feeList[feeType.electrStakeFee]);

        emit electrStakeLog(addrList[addrType.electrStakeAddr] ,  feeList[feeType.electrStakeFee],block.timestamp);

    }


    // 电力领取  30天一次
    function energyReceive() public {

        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(_msgSender() == addrList[addrType.electrAddr] , "user does not have permission");
        // 用户没有权限
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        require(electrStartTime + limitTimeList[limitTimeType.electrIntervalTime] < block.timestamp, "Refusal to contract transactions");
        // 判断第一次领取 需要质押电力
        uint256 months = block.timestamp - electrStartTime / limitTimeList[limitTimeType.electrIntervalTime];


        uint256 amount = months *  feeList[feeType.electrFee];
        electrStartTime += months * limitTimeList[limitTimeType.electrIntervalTime];
        // 判断第一次押金
        usdt.safeTransfer(addrList[addrType.electrAddr] , amount);
        emit energyReceiveLog(addrList[addrType.electrAddr], amount, block.timestamp);

    }



    // 保险领取  一年一次
    function insuranceReceive() public  {

        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        // 拒绝合约交易
        require(_msgSender() == addrList[addrType.insuranceAddr] , "user does not have permission");
        // 不能
        require(schedule == ActionChoices.FINISH, "not FINISH status");
        uint256 amount;
        if (insuranceStartTime == 0 )  {
            amount =  feeList[feeType.insuranceFee];
            usdt.safeTransfer(addrList[addrType.insuranceAddr] , amount);
            insuranceStartTime = block.timestamp;
        } else {
            require(insuranceStartTime +  limitTimeList[limitTimeType.insuranceIntervalTime]< block.timestamp, "Refusal to contract transactions");
            uint256 year = (block.timestamp - insuranceStartTime) / limitTimeList[limitTimeType.insuranceIntervalTime];

            amount = year *  feeList[feeType.insuranceFee];
            insuranceStartTime += year * limitTimeList[limitTimeType.insuranceIntervalTime];
            usdt.safeTransfer(addrList[addrType.insuranceAddr] , amount);
        }

        emit insuranceReceiveLog(addrList[addrType.insuranceAddr] , amount, block.timestamp);

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
    function failDivestment() public whenNotPaused nonReentrant {

    }


    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    function getChoice() public view returns (ActionChoices) {
        return schedule;
    }


    function setSaleIsActive(bool newState_) public onlyOwner {
        saleIsActive = newState_;
    }


}
