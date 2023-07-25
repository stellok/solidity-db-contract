// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// 招标合约
contract Bidding is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 public constant PLATFORM = keccak256("PLATFORM"); // 平台
    bytes32 public constant ADMIN = keccak256("ADMIN"); // 平台
    bytes32 public constant OWNER = keccak256("OWNER"); //

    uint256 startTime; //  开始时间  设置 minerStake
    uint256 public totalSold;

    uint256 public financingShare; // 融资融资股
    uint256 public stakeSharePrice; // 质押股价
    address private financAddr;

    struct userStakeInfo {
        uint256 amount; // 股数
        bool unStake; // 退回
        bool exist; // 存在
    }

    struct minerStakeInfo {
        uint256 amount; // 股数
        uint256 stakeAmount; // 退回
        uint256 nonce; // 退回 ++
        bool unStake; // 退回
        bool exist; // 存在
    }

    // 公司 质押
    struct companyStakeInfo {
        address addr;
        uint256 totalAmount; // 总数
        uint256 stakeAmount; // 质押数量
        bool unStake; // 退回
        bool exist; // 存在
    }

    enum companyType {
        invalid,
        builder,
        builderInsurance,
        insurance,
        operations
    }
    mapping(companyType => companyStakeInfo) companyList;

    //  Type
    enum signType {
        invalid,
        unSubscribe,
        minerStake,
        unMinerStake,
        planStake,
        unPlanStake
    }

    mapping(address => userStakeInfo) public user; // 用户
    mapping(address => minerStakeInfo) public miner; // 矿工

    IERC20 public usdt; // usdt

    bool public isfDdFee; //  是否缴纳尽调费
    bool isPayService; // 是否 缴纳

    address public platformAddr; //平台管理
    address public platformFeeAddr; //平台管理费地址
    address public founderAddr; // 创始人
    address public DDAddr; // 尽调地址

    uint256 public serviceFee; //  服务费 10000
    uint256 public ddFee; //    尽调费 90000  首次

    bool public isInIt;

    uint256 subscribeTime; // 认购时间
    uint256 subscribeLimitTime; // 限时
    uint256 minerStakeLimitTime; // 矿工质押限时
    uint256 public constant maxNftAMOUNT = 10;

    //  创始人质押
    event payServiceFeeLog(
        address addr,
        address to,
        uint256 amount,
        uint256 fee,
        uint256 time
    );

    event payDDFeeLog(address account, uint256 amount, uint256 time);
    event unMinerStakeLog(address account, uint256 amount, uint256 time);
    event uploadProjectLog(address addr, uint256 id, uint256 time);
    event minerIntentMoneyLog(address addr, uint256 id, uint256 time);
    event minerStakeLog(address addr, uint256 id, uint256 time);
    event subscribeLog(
        address addr,
        uint256 stock,
        uint256 amount,
        uint256 time
    );
    event payServiceFeeLog(
        address founderAddr,
        address platformFeeAddr,
        uint256 amount,
        uint256 time
    );

    constructor(
        IERC20 usdtAddr_,
        address founderAddr_,
        address adminAddr_, //  owner
        uint256 service_,
        uint256 ddFee_,
        address ddAddr_,
        address platformFeeAddr_
    ) {
        // _transferOwnership(owner_);
        _setRoleAdmin(PLATFORM, OWNER);
        //        _setRoleAdmin(PLATFORM, ADMIN);
        _setupRole(PLATFORM, _msgSender());
        _setupRole(ADMIN, adminAddr_);

        ddFee = ddFee_; //  尽调费
        DDAddr = ddAddr_; //矿场提供方
        platformAddr = _msgSender(); // 平台管理
        founderAddr = founderAddr_; //创始人
        serviceFee = service_; //  服务费

        startTime = block.timestamp;
        usdt = usdtAddr_;
        platformFeeAddr = platformFeeAddr_;
    }

    //  缴纳服务费
    function payServiceFee() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(_msgSender() == founderAddr, "user does not have permission"); // 创始人 PayServiceFee
        require(isPayService == false, "user does not have permission"); // 创始人
        isPayService = true;
        usdt.safeTransferFrom(_msgSender(), platformFeeAddr, serviceFee); // 缴给
        emit payServiceFeeLog(
            founderAddr,
            platformFeeAddr,
            serviceFee,
            block.timestamp
        );
    }

    //  缴纳尽调费
    function payDDFee() public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(_msgSender() == founderAddr, "user does not have permission"); // 创始人
        require(isfDdFee == false, "user does not have permission"); // 创始人
        isfDdFee = true;
        usdt.safeTransferFrom(_msgSender(), address(this), ddFee); // 缴给
        emit payDDFeeLog(founderAddr, ddFee, block.timestamp);
    }

    // 退回尽调费
    function refundDDFee() public onlyRole(ADMIN) {
        require(isfDdFee == true, "user does not have permission");
        isfDdFee = false;

        usdt.safeTransfer(founderAddr, ddFee);
        emit payDDFeeLog(founderAddr, ddFee, block.timestamp);
    }

    // 矿工质押
    function minerIntentMoney(
        uint256 amount,
        uint256 expire,
        bytes memory signature
    ) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(expire > block.timestamp, "not yet expired"); // 还没到期
        require(miner[_msgSender()].exist == false, "participated"); // 参与过了

        bytes32 msgSplice = keccak256(
            abi.encodePacked(
                address(this),
                "6b9119e6",
                _msgSender(),
                amount,
                expire
            )
        );

        _checkRole(
            PLATFORM,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );

        usdt.safeTransferFrom(_msgSender(), address(this), amount);
        miner[_msgSender()].amount += amount;
        miner[_msgSender()].exist = true;
        emit minerIntentMoneyLog(_msgSender(), amount, block.timestamp);
    }

    //    退款矿工质押
    function unMinerIntentMoney(
        uint256 expire,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(miner[_msgSender()].exist == true, "miner  does not exist"); //   用户不存在
        require(miner[_msgSender()].nonce == nonce, "nonce invalid"); //   无效
        require(
            miner[_msgSender()].amount >= amount && amount > 0,
            "amount invalid"
        ); //   无效
        require(expire > block.timestamp, "not yet expired"); // 还没到期

        bytes32 msgSplice = keccak256(
            abi.encodePacked(
                address(this),
                "b13c8aa8",
                _msgSender(),
                expire,
                amount,
                nonce
            )
        );
        _checkRole(
            PLATFORM,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );

        miner[_msgSender()].amount -= amount;
        miner[_msgSender()].nonce += 1;
        usdt.safeTransfer(_msgSender(), miner[_msgSender()].amount);
        emit unMinerStakeLog(
            _msgSender(),
            miner[_msgSender()].amount,
            block.timestamp
        );
    }

    // 开启认购
    function startSubscribe(
        uint256 financingShare_,
        uint256 stakeSharePrice_,
        uint256 subscribeTime_,
        uint256 subscribeLimitTime_
    ) public onlyRole(PLATFORM) {
        require(financingShare_ > 0, "financingShare cannot be zero"); //  不能为零
        require(stakeSharePrice_ > 0, "subscribeLimitTime_ cannot be zero"); //  未开启
        require(subscribeTime_ > 0, "subscribeTime_ cannot be zero"); //  不能为零
        require(subscribeLimitTime_ > 0, "subscribeLimitTime_ cannot be zero"); //  未开启

        financingShare = financingShare_; // 融资融资股
        stakeSharePrice = stakeSharePrice_;
        subscribeTime = subscribeTime_;
        subscribeLimitTime = subscribeLimitTime_;
    }

    // @param stock 认购数
    // @param amount 5% stake
    function subscribe(uint256 stock) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(stock > 0, "cannot be less than zero");
        require(financingShare * 2 > totalSold, "sold out"); // 售完
        require(subscribeTime > 0, "UnStart subscribe"); //  未开启
        require(stock <= maxNftAMOUNT, "stock > 10");

        require(
            subscribeTime + subscribeLimitTime > block.timestamp,
            "time expired"
        );
        require(stock > 0, "Not yet subscribed"); // 数量 大于0

        if (financingShare * 2 - totalSold < stock) {
            stock = financingShare * 2 - totalSold;
        }
        totalSold += stock;
        user[_msgSender()].amount += stock;
        user[_msgSender()].exist = true;
        usdt.safeTransferFrom(
            _msgSender(),
            address(this),
            stock * stakeSharePrice
        );
        emit subscribeLog(
            _msgSender(),
            stock,
            stock * stakeSharePrice,
            block.timestamp
        );
    }

    //    退款用户认缴
    function unSubscribe(uint256 expire, bytes memory signature) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(user[_msgSender()].exist == true, "company  does not exist"); //   用户不存在
        require(user[_msgSender()].unStake == false, "company  does not exist"); //

        bytes32 msgSplice = keccak256(
            abi.encodePacked(_msgSender(), expire, address(this), "dfb08b8d")
        );
        _checkRole(
            PLATFORM,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );

        user[_msgSender()].unStake = true;
        usdt.safeTransfer(_msgSender(), user[_msgSender()].amount);
        emit minerStakeLog(
            _msgSender(),
            user[_msgSender()].amount,
            block.timestamp
        );
    }

    // 矿工质押
    function minerStake(
        uint256 stakeAmount,
        uint256 expire,
        bytes memory signature
    ) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(expire > block.timestamp, "not yet expired"); // 还没到期
        require(miner[_msgSender()].exist == true, "participated"); // 参与过了
        require(stakeAmount > miner[_msgSender()].amount, "participated"); // 参与过了

        bytes32 msgSplice = keccak256(
            abi.encodePacked(
                address(this),
                "bdcc95e1",
                _msgSender(),
                stakeAmount,
                expire
            )
        );

        _checkRole(
            PLATFORM,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );

        usdt.safeTransferFrom(
            _msgSender(),
            address(this),
            stakeAmount - miner[_msgSender()].amount
        );
        miner[_msgSender()].stakeAmount = stakeAmount;
        miner[_msgSender()].amount = 0;
        emit minerStakeLog(_msgSender(), stakeAmount, block.timestamp);
    }

    // 方案质押
    function planStake(
        companyType role,
        uint256 totalAmount,
        uint256 stakeAmount,
        uint256 expire,
        bytes memory signature
    ) public {
        require(_msgSender() == tx.origin, "Refusal to contract transactions");
        require(expire > block.timestamp, "not yet expired"); // 还没到期
        require(companyList[role].exist == false, "participated"); // 参与过了

        bytes32 msgSplice = keccak256(
            abi.encodePacked(
                address(this),
                "ec853128",
                _msgSender(),
                role,
                totalAmount,
                stakeAmount,
                expire
            )
        );
        _checkRole(
            PLATFORM,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );

        companyList[role].totalAmount = totalAmount;
        companyList[role].stakeAmount = stakeAmount;
        companyList[role].exist = true;
        companyList[role].addr = _msgSender();
        usdt.safeTransferFrom(_msgSender(), address(this), stakeAmount);
        emit minerStakeLog(_msgSender(), stakeAmount, block.timestamp);
    }

    //    退款方案方质押
    function unPlanStake(companyType role) public onlyRole(ADMIN) {
        require(companyList[role].exist == true, "company  does not exist"); //   用户不存在
        require(
            companyList[role].unStake == false,
            "cannot be repeated unStake"
        );

        companyList[role].unStake = true;
        usdt.safeTransfer(
            companyList[role].addr,
            companyList[role].stakeAmount
        );
        emit minerStakeLog(
            companyList[role].addr,
            companyList[role].stakeAmount,
            block.timestamp
        );
    }

    function transferAmount(uint256 amount) public {
        require(financAddr != address(0), "address is null");
        require(_msgSender() == financAddr, "only invoke by owner");
        usdt.transfer(financAddr, amount);
    }

    function setFinancing(address addr) public onlyRole(PLATFORM) {
        require(addr.isContract(), "addr must Contract address");
        financAddr = addr;
    }

    // todo 返回质押  minerStake
    function IntentMoneyAmount(address account) public view returns (uint256) {
        return miner[account].amount;
    }

    // 查看认缴金额
    function viewSubscribe(address account) public view returns (uint256) {
        return user[account].amount;
    }

    function pause() public whenNotPaused onlyRole(ADMIN) {
        _pause();
    }

    function unpause() public whenPaused onlyRole(ADMIN) {
        _unpause();
    }

    function payDD() public onlyRole(ADMIN) {
        usdt.safeTransfer(platformFeeAddr, ddFee);
    }

    // 紧急提现
    function withdraw(uint256 amount, address addr) public onlyRole(OWNER) {
        usdt.safeTransfer(addr, amount);
    }

    function isParticipated(address account) public view returns (bool) {
        return miner[account].exist;
    }
}
