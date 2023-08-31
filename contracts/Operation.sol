// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Operation is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public USDT;
    IERC721 public NFT;
    uint256 public expire;
    uint256 public totalShares;
    uint256 public lastExecuted;
    mapping(uint256 => uint256) monthlyInfo; //The total amount paid each month
    struct dividendsInfo {
        bool exist; //
        uint256 totalMonthlyBalance; //Total monthly balance
        uint256 dividend; //dividend
        mapping(uint256 => bool) isReceive; //Receive
    }

    //<index,dividendsInfo>
    mapping(uint256 => dividendsInfo) receiveRecord; //Claim records

    event paymentLog(uint256 index, uint256 amount, uint256 time);
    event doMonthlyTaskLog(
        uint256 index,
        uint256 totalMonthlyBalance,
        uint256 dividend,
        uint256 time
    );
    event receiveDividendsLog(
        address addr,
        uint256 index,
        uint256[] tokenList,
        uint256 amount,
        uint256 time
    );

    //start time
    uint256 operationStartTime;
    uint256 public spvStartTime;
    uint256 electrStartTime;
    uint256 insuranceStartTime;
    uint256 buildInsuranceStartTime;

    // AddrType
    struct AddrType {
        address builderAddr; //builder
        address buildInsuranceAddr; //build insurance address
        address insuranceAddr; //insurance provider
        address operationsAddr; //operation and maintenance provider
        address spvAddr; //SPV address
        address electrStakeAddr; //Electricity pledge address
        address electrAddr; //electric man
    }

    AddrType public addrType;

    // FeeType
    struct FeeType {
        uint256 firstBuildFee; //first build
        uint256 remainBuildFee; //Remaining construction funds
        uint256 operationsFee; //shipping fee
        uint256 electrFee; //electricity bill
        uint256 electrStakeFee; //Pledge electricity fee
        uint256 buildInsuranceFee; //build premium
        uint256 insuranceFee; //warranty fee
        uint256 spvFee; //trust management fee
        uint256 publicSalePlatformFee; //public sale platform fee
        uint256 remainPlatformFee; //public sale platform fee
    }
    FeeType public feeType;

    //time limit interval Interval
    struct LimitTimeType {
        uint256 whitelistPaymentLimitTime; //Whitelist time limit
        uint256 publicSaleLimitTime; //public sale for a limited time
        uint256 startBuildLimitTime; // Start of construction time
        uint256 bargainLimitTime; //Pick up the start time
        uint256 remainPaymentLimitTime; //Whitelist start time
        uint256 electrIntervalTime; //Power interval
        uint256 operationIntervalTime; //Time between operations
        uint256 insuranceIntervalTime; //Insurance sub-settlement time
        uint256 spvIntervalTime; //Trust interval
    }
    LimitTimeType public limitTimeType;
    uint256 public reserveFund;

    constructor(
        uint256 reserveFund_,
        IERC20 usdt,
        IERC721 nft,
        uint256 totalShares_,
        uint256 expire_,
        uint256 operationStartTime_,
        uint256 spvStartTime_,
        uint256 electrStartTime_,
        uint256 insuranceStartTime_,
        FeeType memory feeList_, // fees
        AddrType memory addrList_, // address
        LimitTimeType memory limitTimeList_ // times
    ) {
        reserveFund = reserveFund_;

        USDT = usdt;
        NFT = nft;
        totalShares = totalShares_;
        lastExecuted = block.timestamp;
        expire = expire_;

        operationStartTime = operationStartTime_;
        spvStartTime = spvStartTime_;
        electrStartTime = electrStartTime_;
        insuranceStartTime = insuranceStartTime_;

        addrType = addrList_;
        limitTimeType = limitTimeList_;
        feeType = feeList_;
    }

    event operationsReceiveLog(address addr_, uint256 amount_, uint256 time_);
    event spvReceiveLog(
        address addr_,
        uint256 amount_,
        uint256 year,
        uint256 time_
    );
    event electrStakeLog(address feeAddr, uint256 amount, uint256 time_);

    event energyReceiveLog(
        address addr,
        uint256 mouth,
        uint256 amount_,
        uint256 time_
    );
    event insuranceReceiveLog(
        uint256 year_,
        address energyAddr_,
        uint256 amount_,
        uint256 time_
    );

    event buildInsuranceReceiveLog(
        address energyAddr_,
        uint256 amount_,
        uint256 time_
    );

    //pay
    function income(uint256 amount) public nonReentrant {
        require(amount > 0, "amount cannot be zero"); // 不能为零
        USDT.safeTransferFrom(msg.sender, address(this), amount);
        uint256 index = phaseIndex();
        monthlyInfo[index] += amount;
        emit paymentLog(index, amount, block.timestamp);
    }

    //Check the dividends during the inspection phase
    function doMonthlyTask(uint256 index) public nonReentrant {
        require(index < phaseIndex(), "index must < current phase");
        require(monthlyInfo[index] > 0, "this Phase total amount is 0");
        require(receiveRecord[index].exist == false, "has been comforted");
        uint256 total = monthlyInfo[index] - reserveFund;
        receiveRecord[index].exist = true;
        receiveRecord[index].totalMonthlyBalance = total;
        receiveRecord[index].dividend = total / totalShares;
        emit doMonthlyTaskLog(
            index,
            total,
            total / totalShares,
            block.timestamp
        );
    }

    //Receive dividends
    function receiveDividends(
        uint256 index,
        uint256[] memory tokenList
    ) public nonReentrant {
        require(monthlyInfo[index] > 0, "this Phase total amount is 0");
        require(tokenList.length > 0, "cannot be zero");
        require(
            receiveRecord[index].exist == true,
            "This month's dividend has not been settled"
        ); //This month's dividend has not yet been settled
        require(
            receiveRecord[index].totalMonthlyBalance >=
                tokenList.length * receiveRecord[index].dividend,
            "Insufficient dividend balance"
        ); //Insufficient dividend balance
        for (uint i = 0; i < tokenList.length; i++) {
            require(
                NFT.ownerOf(tokenList[i]) == msg.sender,
                "You do not have permission"
            ); //You don't have permissions
            require(
                receiveRecord[index].isReceive[tokenList[i]] == false,
                "Cannot be claimed repeatedly"
            ); //Duplicate claims are not possible

            receiveRecord[index].isReceive[tokenList[i]] = true;
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

    //O&M Collect once every 30 days
    function operationsReceive() public nonReentrant {
        require(
            _msgSender() == addrType.operationsAddr,
            "user does not have permission"
        );
        require(operationStartTime > 0, "Operation start time must be greater than 0");
        require(
            operationStartTime + limitTimeType.operationIntervalTime <
                block.timestamp,
            "Refusal to contract transactions"
        );
        //Judging the first claim requires pledge electricity // 3000
        uint256 months = block.timestamp -
            (operationStartTime + limitTimeType.operationIntervalTime) /
            limitTimeType.operationIntervalTime;

        uint256 amount = months * feeType.operationsFee;
        operationStartTime += months * limitTimeType.operationIntervalTime;
        USDT.safeTransfer(addrType.operationsAddr, amount);
        emit operationsReceiveLog(_msgSender(), amount, block.timestamp);
    }

    //SPV pickup
    function spvReceive() public nonReentrant {
        require(
            _msgSender() == addrType.spvAddr,
            "user does not have permission"
        );
        require(spvStartTime > 0, "SPV start time must be greater than 0");
        require(
            spvStartTime + limitTimeType.spvIntervalTime < block.timestamp,
            "Refusal to contract transactions"
        );
        uint256 year = (block.timestamp - spvStartTime) /
            limitTimeType.spvIntervalTime;

        uint256 amount = year * feeType.spvFee;
        spvStartTime += year * limitTimeType.spvIntervalTime;
        USDT.safeTransfer(addrType.spvAddr, amount);

        emit spvReceiveLog(addrType.spvAddr, amount, year, block.timestamp);
    }

    bool electrStakeLock;

    //Electricity deposit collection
    function electrStake() public nonReentrant {
        require(
            _msgSender() == addrType.electrStakeAddr,
            "user does not have permission"
        );
        require(electrStakeLock == false, "You have claimed it");
        //To determine the first claim requires pledge electricity TODO time calculation formula
        electrStakeLock = true;
        USDT.safeTransfer(addrType.electrStakeAddr, feeType.electrStakeFee);
        emit electrStakeLog(
            addrType.electrStakeAddr,
            feeType.electrStakeFee,
            block.timestamp
        );
    }

    //Electricity collection once every 30 days
    function energyReceive() public nonReentrant {
        require(
            _msgSender() == addrType.electrAddr,
            "user does not have permission"
        );
        require(
            electrStartTime > 0,
            "Electr start time must be greater than 0"
        );
        require(
            electrStartTime + limitTimeType.electrIntervalTime <
                block.timestamp,
            "Refusal to contract transactions"
        );
        //It is judged that the first claim requires pledge of electricity
        uint256 months = (block.timestamp - electrStartTime) /
            limitTimeType.electrIntervalTime;
        uint256 amount = months * feeType.electrFee;
        electrStartTime += months * limitTimeType.electrIntervalTime;
        //Judge the first deposit
        USDT.safeTransfer(addrType.electrAddr, amount);
        emit energyReceiveLog(
            addrType.electrAddr,
            months,
            amount,
            block.timestamp
        );
    }

    //Claim insurance once a year
    function insuranceReceive() public nonReentrant {
        require(
            _msgSender() == addrType.insuranceAddr,
            "user does not have permission"
        );
        require(
            insuranceStartTime > 0,
            "Insurance start time must be greater than 0"
        );
        require(
            insuranceStartTime + limitTimeType.insuranceIntervalTime <
                block.timestamp,
            "Refusal to contract transactions"
        );
        uint256 year = (block.timestamp - insuranceStartTime) /
            limitTimeType.insuranceIntervalTime;
        uint256 amount = year * feeType.insuranceFee;
        insuranceStartTime += year * limitTimeType.insuranceIntervalTime;
        USDT.safeTransfer(addrType.insuranceAddr, amount);

        emit insuranceReceiveLog(
            year,
            addrType.insuranceAddr,
            amount,
            block.timestamp
        );
    }

    //TODO withdraw is overdue

    function monthDividend(uint256 index) public view returns (uint256) {
        return receiveRecord[index].dividend;
    }

    function phaseIndex() public view returns (uint256) {
        return (block.timestamp - lastExecuted) / expire;
    }

    function isReceive(
        uint256 index,
        uint256 tokenId
    ) public view returns (bool) {
        return receiveRecord[index].isReceive[tokenId];
    }
}
