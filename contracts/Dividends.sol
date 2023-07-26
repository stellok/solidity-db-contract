// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Dividends is ReentrancyGuard{

    using SafeERC20 for IERC20;
    IERC20 public USDT;
    IERC721 public NFT;
    uint256 public FinancingFee;
    address public FinancingAddr;

    uint256 public totalShares;
    uint256 public lastExecuted;
    mapping( uint256 => uint256)  monthlyInfo; // 每月支付总金额
    struct dividendsInfo {
        bool exist; // 存在
        uint256 totalMonthlyBalance;      // 月总余额
        uint256 dividend;     // 股息
        mapping(uint256 => bool) isReceive; // 领取
    }

    mapping(uint256 => dividendsInfo) receiveRecord ;     // 领取记录
    uint256[] public monthlyList;

    event paymentLog( uint256 monthlyTime,uint256 amount, uint256 time);
    event doMonthlyTaskLog( uint256 monthlyTime,uint256 totalMonthlyBalance,uint256  dividend, uint256 time);
    event receiveDividendsLog(address addr, uint256 monthlyTime,uint256[]  tokenList,uint256  amount, uint256 time);
    constructor(
        IERC20 usdt,
        IERC721 nft,
        uint256 financingFee_,
        address financingAddr_,
        uint256 totalShares_
    ) {
        USDT = usdt;
        NFT = nft;
        FinancingFee = financingFee_;
        FinancingAddr = financingAddr_;
        totalShares = totalShares_;
        lastExecuted = block.timestamp;
        monthlyInfo[lastExecuted] = 0;
        monthlyList.push(lastExecuted);
    }

    // 支付
    function payment(uint256 amount) public nonReentrant  {
        require(amount > 0, "amount cannot be zero");  // 不能为零

        USDT.safeTransferFrom(msg.sender, address(this), amount);

        if (block.timestamp >= lastExecuted + 30 days) {
            lastExecuted = block.timestamp;
        }
        monthlyInfo[lastExecuted] += amount;
        emit paymentLog(lastExecuted,amount, block.timestamp );
    }

    // 检查当月分红
    function doMonthlyTask(uint256 index) public nonReentrant {
        require(msg.sender == tx.origin, "Refusal to contract transactions");
        require(monthlyList[index] > 0, "amount cannot be zero");  // 不能为零
        require(monthlyList[index] +  30 days < block.timestamp, "no time");  // 没到时间呢
        require(receiveRecord[monthlyList[index]].exist == false, "has been comforted");  // 已经被舒适化

        uint256 total = monthlyInfo[monthlyList[index]] - FinancingFee;
        receiveRecord[monthlyList[index]].exist == true;
        USDT.safeTransfer(FinancingAddr, FinancingFee);
        receiveRecord[monthlyList[index]].totalMonthlyBalance = total;
        receiveRecord[monthlyList[index]].dividend = total / totalShares;
        emit doMonthlyTaskLog( monthlyList[index], total, total / totalShares, block.timestamp);
    }

    // 领取分红
    function receiveDividends( uint256 index,uint256[] memory tokenList) public nonReentrant {
        require(msg.sender == tx.origin, "Refusal to contract transactions");
        require(tokenList.length > 0 , "cannot be zero");
        require( receiveRecord[monthlyList[index]].exist == true, "This month's dividend has not been settled"); // 本月分红还没结算
        require( receiveRecord[monthlyList[index]].totalMonthlyBalance >= tokenList.length * receiveRecord[monthlyList[index]].dividend, "Insufficient dividend balance"); // 分红余额不足
        for ( uint i = 0; i < tokenList.length; i++ ) {
            require(NFT.ownerOf(tokenList[i]) == msg.sender, "You do not have permission");  // 你没有权限
            require(receiveRecord[monthlyList[index]].isReceive[tokenList[i]] == false, "Cannot be claimed repeatedly");  // 无法重复领取

            receiveRecord[monthlyList[index]].isReceive[tokenList[i]] == true;
            receiveRecord[monthlyList[index]].totalMonthlyBalance -= receiveRecord[monthlyList[index]].dividend;
        }
        USDT.safeTransfer(msg.sender, tokenList.length * receiveRecord[monthlyList[index]].dividend);
        emit receiveDividendsLog(msg.sender,  monthlyList[index], tokenList,  tokenList.length * receiveRecord[monthlyList[index]].dividend, block.timestamp);
    }

}
