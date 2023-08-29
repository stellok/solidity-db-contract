// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Dividends is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public USDT;
    IERC721 public NFT;
    uint256 public FinancingFee;
    address public FinancingAddr;
    uint256 public expire;
    uint256 public totalShares;
    uint256 public lastExecuted;
    mapping(uint256 => uint256) monthlyInfo; // 每月支付总金额
    struct dividendsInfo {
        bool exist; // 存在
        uint256 totalMonthlyBalance; // 月总余额
        uint256 dividend; // 股息
        mapping(uint256 => bool) isReceive; // 领取
    }

    //<index,dividendsInfo>
    mapping(uint256 => dividendsInfo) receiveRecord; // 领取记录

    event paymentLog(uint256 index, uint256 amount, uint256 time);
    event doMonthlyTaskLog(
        uint256 monthlyTime,
        uint256 totalMonthlyBalance,
        uint256 dividend,
        uint256 time
    );
    event receiveDividendsLog(
        address addr,
        uint256 monthlyTime,
        uint256[] tokenList,
        uint256 amount,
        uint256 time
    );

    //start time
    uint256 operationStartTime;
    uint256 spvStartTime;
    uint256 electrStartTime;
    uint256 insuranceStartTime;

    // AddrType
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

    // FeeType
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
    LimitTimeType public limitTimeType;

    constructor(
        IERC20 usdt,
        IERC721 nft,
        uint256 financingFee_,
        address financingAddr_,
        uint256 totalShares_,
        uint256 expire_,
        FeeType memory feeList_, // fees
        AddrType memory addrList_, // address  集合 
        LimitTimeType memory limitTimeList_// times 集合 
    ) {
        USDT = usdt;
        NFT = nft;
        FinancingFee = financingFee_;
        FinancingAddr = financingAddr_;
        totalShares = totalShares_;
        lastExecuted = block.timestamp;
        expire = expire_;

        operationStartTime = lastExecuted;
        spvStartTime = lastExecuted;
        electrStartTime = lastExecuted;
        insuranceStartTime = lastExecuted;

        addrType = addrList_;
        limitTimeType = limitTimeList_;
        feeType = feeList_;
    }



    event operationsReceiveLog(address addr_, uint256 amount_, uint256 time_);
    event spvReceiveLog(address addr_, uint256 amount_, uint256 time_);
    event electrStakeLog(address feeAddr, uint256 amount, uint256 time_);

    event energyReceiveLog(
        address addr,
        uint256 mouth,
        uint256 amount_,
        uint256 time_
    );
    event insuranceReceiveLog(
        address energyAddr_,
        uint256 amount_,
        uint256 time_
    );

    // 支付
    function payment(uint256 amount) public nonReentrant {
        require(amount > 0, "amount cannot be zero"); // 不能为零
        USDT.safeTransferFrom(msg.sender, address(this), amount);
        uint256 index = phaseIndex();
        monthlyInfo[index] += amount;
        emit paymentLog(index, amount, block.timestamp);
    }

    // 检查阶段分红
    function doMonthlyTask(uint256 index) public nonReentrant {
        require(index < phaseIndex(), "index must < current phase");
        require(monthlyInfo[index] > 0, "this Phase total amount is 0");
        require(receiveRecord[index].exist == false, "has been comforted");
        uint256 total = monthlyInfo[index] - FinancingFee;
        receiveRecord[index].exist = true;
        USDT.safeTransfer(FinancingAddr, FinancingFee);
        receiveRecord[index].totalMonthlyBalance = total;
        receiveRecord[index].dividend = total / totalShares;
        emit doMonthlyTaskLog(
            index,
            total,
            total / totalShares,
            block.timestamp
        );
    }

    // 领取分红
    function receiveDividends(
        uint256 index,
        uint256[] memory tokenList
    ) public nonReentrant {
        require(monthlyInfo[index] > 0, "this Phase total amount is 0");
        require(tokenList.length > 0, "cannot be zero");
        require(
            receiveRecord[index].exist == true,
            "This month's dividend has not been settled"
        ); // 本月分红还没结算
        require(
            receiveRecord[index].totalMonthlyBalance >=
                tokenList.length * receiveRecord[index].dividend,
            "Insufficient dividend balance"
        ); // 分红余额不足
        for (uint i = 0; i < tokenList.length; i++) {
            require(
                NFT.ownerOf(tokenList[i]) == msg.sender,
                "You do not have permission"
            ); // 你没有权限
            require(
                receiveRecord[index].isReceive[tokenList[i]] == false,
                "Cannot be claimed repeatedly"
            ); // 无法重复领取

            receiveRecord[index].isReceive[tokenList[i]] == true;
            receiveRecord[index].totalMonthlyBalance -= receiveRecord[index]
                .dividend;
        }
        USDT.safeTransfer(
            msg.sender,
            tokenList.length * receiveRecord[index].dividend
        );
        emit receiveDividendsLog(
            msg.sender,
            index,
            tokenList,
            tokenList.length * receiveRecord[index].dividend,
            block.timestamp
        );
    }

    // 运维 领取 30天一次
    function operationsReceive() public nonReentrant {
        require(
            _msgSender() == addrType.operationsAddr,
            "user does not have permission"
        );
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
        USDT.safeTransfer(addrType.operationsAddr, amount);
        emit operationsReceiveLog(_msgSender(), amount, block.timestamp);
    }

    //  spv 领取
    function spvReceive() public nonReentrant {
        require(
            _msgSender() == addrType.spvAddr,
            "user does not have permission"
        );

        uint256 amount;
        if (spvStartTime == 0) {
            amount = feeType.spvFee;
            USDT.safeTransfer(addrType.spvAddr, amount);
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
            USDT.safeTransfer(addrType.spvAddr, amount);
        }
        emit spvReceiveLog(addrType.spvAddr, amount, block.timestamp);
    }

    bool electrStakeLock;

    //  押金
    function electrStake() public nonReentrant {
        require(
            _msgSender() == addrType.electrStakeAddr,
            "user does not have permission"
        );
        require(electrStakeLock == false, "not FINISH status");
        // 判断第一次领取 需要质押电力  todo 时间计算公式
        electrStakeLock = true;
        USDT.safeTransfer(addrType.electrStakeAddr, feeType.electrStakeFee);
        emit electrStakeLog(
            addrType.electrStakeAddr,
            feeType.electrStakeFee,
            block.timestamp
        );
    }

    // 电力领取  30天一次
    function energyReceive() public nonReentrant {
        require(
            _msgSender() == addrType.electrAddr,
            "user does not have permission"
        );
        require(
            electrStartTime + limitTimeType.electrIntervalTime <
                block.timestamp,
            "Refusal to contract transactions"
        );
        // 判断第一次领取 需要质押电力
        uint256 months = (block.timestamp - electrStartTime) /
            limitTimeType.electrIntervalTime;
        uint256 amount = months * feeType.electrFee;
        electrStartTime += months * limitTimeType.electrIntervalTime;
        // 判断第一次押金
        USDT.safeTransfer(addrType.electrAddr, amount);
        emit energyReceiveLog(
            addrType.electrAddr,
            months,
            amount,
            block.timestamp
        );
    }

    // 保险领取  一年一次
    function insuranceReceive() public nonReentrant {
        require(
            _msgSender() == addrType.insuranceAddr,
            "user does not have permission"
        );
        // 不能
        uint256 amount;
        if (insuranceStartTime == 0) {
            amount = feeType.insuranceFee;
            USDT.safeTransfer(addrType.insuranceAddr, amount);
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
            USDT.safeTransfer(addrType.insuranceAddr, amount);
        }
        emit insuranceReceiveLog(
            addrType.insuranceAddr,
            amount,
            block.timestamp
        );
    }

    function monthDividend(uint256 index) public view returns (uint256) {
        return receiveRecord[index].dividend;
    }

    function phaseIndex() public view returns (uint256) {
        return (block.timestamp - lastExecuted) / expire;
    }
}
