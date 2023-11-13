// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";

//Tender contracts
contract Bidding is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 public constant PLATFORM_ROLE = keccak256("PLATFORM_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    uint256 startTime; //Start time minerStake
    uint256 public totalSold;

    uint256 public financingShare; //Financing Unit
    uint256 public stakeSharePrice; //Stake share price
    address private financAddr;

    struct userStakeInfo {
        uint256 amount; //Number of shares
        bool unStake; //return
        bool exist; //exist
    }

    struct minerInfo {
        uint256 amount; //Number of shares
        uint256 stakeAmount;
        uint256 nonce;
        bool exist;
    }

    struct minerStakeInfo {
        uint256 nonce;
        bool unStake;
        bool hadStaked;
        uint256 stakeAmount;
        bool exist; // Whether a deposit has been paid
    }

    //Company staking
    struct companyStakeInfo {
        address addr;
        uint256 totalAmount; //total
        uint256 stakeAmount; //Number of stakes
        bool unStake;
        bool exist;
    }

    enum companyType {
        invalid,
        builder,
        builderInsurance,
        insurance,
        operations
    }
    mapping(companyType => companyStakeInfo) companyList;

    mapping(address => userStakeInfo) public user; // user
    mapping(address => mapping(uint => minerInfo)) public miner; //miner
    mapping(address => minerStakeInfo) public stakeMiner; //miner

    IERC20 public usdt; // usdt

    bool public isDdFee; //Whether due diligence fees are paid
    bool public isPayService; //Whether or not to pay
    bool public isPayMinerToSpv; //Whether miner fees are paid
    bool public isPayDD;

    address public platformAddr; //Platform management
    address public platformFeeAddr; //Platform management fee address
    address public spvAddr; //SPV address
    address public founderAddr; //founder
    address public DDAddr; //Due diligence address

    uint256 public serviceFee; //Service fee 10000
    uint256 public ddFee; //Due diligence fee of 90,000 for the first time

    bool public isInIt;

    uint256 subscribeTime; //Subscription time
    uint256 subscribeLimitTime; //Limited time
    uint256 minerStakeLimitTime; //Miner staking time limit
    uint256 public subscribeMax;
    uint256 public userMax;

    event unSubscribeLog(address addr, uint256 id, uint256 time);
    event startSubscribeLog(
        uint256 financingShare_,
        uint256 stakeSharePrice_,
        uint256 subscribeTime_,
        uint256 subscribeLimitTime_
    );

    event payDDLog(address account, uint256 amount, uint256 time);
    event payDDFeeLog(address account, uint256 amount, uint256 time);
    event refundDDFeeLog(address account, uint256 amount, uint256 time);
    event unMinerStakeLog(address account, uint256 amount, uint256 time);
    event unMinerIntentMoneyLog(
        address account,
        uint256 amount,
        uint256 time,
        uint256 id
    );
    event minerIntentMoneyLog(
        address addr,
        uint256 amount,
        uint256 time,
        uint256 id
    );
    event minerStakeLog(address addr, uint256 id, uint256 time);
    event unPlanStakeLog(
        address addr,
        uint256 id,
        uint256 time,
        companyType role
    );
    event planStakeLog(
        address addr,
        uint256 id,
        uint256 time,
        companyType role
    );
    event payMinerToSpvLog(address account, uint256 amount, uint256 time);
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
        address platformFeeAddr_,
        address spvAddr_,
        address owner_,
        uint256 subscribeMax_,
        uint256 userMax_
    ) {
        _setRoleAdmin(ADMIN_ROLE, EMERGENCY_ROLE);
        _setRoleAdmin(PLATFORM_ROLE, ADMIN_ROLE);

        _setupRole(PLATFORM_ROLE, _msgSender()); //
        _setupRole(ADMIN_ROLE, adminAddr_); //
        _setupRole(EMERGENCY_ROLE, owner_);

        ddFee = ddFee_; //Due diligence fees
        DDAddr = ddAddr_; //Mine provider
        platformAddr = _msgSender(); //Platform management
        founderAddr = founderAddr_; //founder
        serviceFee = service_; //service charge

        spvAddr = spvAddr_;
        startTime = block.timestamp;
        usdt = usdtAddr_;
        platformFeeAddr = platformFeeAddr_;

        subscribeMax = subscribeMax_;
        userMax = userMax_;
    }

    //Pay the service fee
    function payServiceFee() public nonReentrant {
        require(_msgSender() == founderAddr, "user does not have permission"); //Founder PayServiceFee
        require(isPayService == false, "user does not have permission"); //founder
        isPayService = true;
        usdt.safeTransferFrom(_msgSender(), platformFeeAddr, serviceFee); //Paid
        emit payServiceFeeLog(
            founderAddr,
            platformFeeAddr,
            serviceFee,
            block.timestamp
        );
    }

    //Pay the due diligence fee
    function payDDFee() public nonReentrant {
        require(_msgSender() == founderAddr, "user does not have permission"); //founder
        require(isDdFee == false, "user does not have permission"); //founder
        isDdFee = true;
        usdt.safeTransferFrom(_msgSender(), address(this), ddFee); //Paid
        emit payDDFeeLog(founderAddr, ddFee, block.timestamp);
    }

    //Refund of due diligence fees
    function refundDDFee() public nonReentrant onlyRole(ADMIN_ROLE) {
        require(isDdFee == true, "user does not have permission");
        isDdFee = false;

        usdt.safeTransfer(founderAddr, ddFee);
        emit refundDDFeeLog(founderAddr, ddFee, block.timestamp);
    }

    //Miner staking
    function minerIntentMoney(
        uint256 id,
        uint256 amount,
        uint256 expire,
        bytes memory signature
    ) public nonReentrant whenNotPaused {
        require(expire > block.timestamp, "not yet expired"); //It hasn't expired yet
        require(miner[_msgSender()][id].exist == false, "participated"); // Participated

        bytes32 msgSplice = keccak256(
            abi.encodePacked(
                address(this),
                "6d14f0d8",
                _msgSender(),
                amount,
                expire,
                id
            )
        );

        _checkRole(
            PLATFORM_ROLE,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );

        usdt.safeTransferFrom(_msgSender(), address(this), amount);
        miner[_msgSender()][id].amount += amount;
        miner[_msgSender()][id].exist = true;
        stakeMiner[_msgSender()].exist = true;
        emit minerIntentMoneyLog(_msgSender(), amount, block.timestamp, id);
    }

    //Refund miner staking
    function unMinerIntentMoney(
        uint256 id,
        uint256 expire,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public nonReentrant {
        require(miner[_msgSender()][id].exist == true, "miner  does not exist"); //The user does not exist
        require(miner[_msgSender()][id].nonce == nonce, "nonce invalid");
        require(
            miner[_msgSender()][id].amount >= amount && amount > 0,
            "amount invalid"
        );
        require(expire > block.timestamp, "not yet expired"); //It hasn't expired yet

        bytes32 msgSplice = keccak256(
            abi.encodePacked(
                address(this),
                "3077df07",
                _msgSender(),
                expire,
                amount,
                nonce,
                id
            )
        );
        _checkRole(
            PLATFORM_ROLE,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );

        miner[_msgSender()][id].amount -= amount;
        miner[_msgSender()][id].nonce += 1;
        usdt.safeTransfer(_msgSender(), amount);
        emit unMinerIntentMoneyLog(_msgSender(), amount, block.timestamp, id);
    }

    //Open subscription
    function startSubscribe(
        uint256 financingShare_,
        uint256 stakeSharePrice_,
        uint256 subscribeTime_,
        uint256 subscribeLimitTime_
    ) public nonReentrant whenNotPaused onlyRole(PLATFORM_ROLE) {
        require(financingShare_ > 0, "financingShare cannot be zero"); //Cannot be zero
        require(stakeSharePrice_ > 0, "subscribeLimitTime_ cannot be zero"); //Not turned on
        require(subscribeTime_ > 0, "subscribeTime_ cannot be zero"); //Cannot be zero
        require(subscribeLimitTime_ > 0, "subscribeLimitTime_ cannot be zero"); //Not turned on

        financingShare = financingShare_; //Financing Unit
        stakeSharePrice = stakeSharePrice_;
        subscribeTime = subscribeTime_;
        subscribeLimitTime = subscribeLimitTime_;

        emit startSubscribeLog(
            financingShare_,
            stakeSharePrice_,
            subscribeTime_,
            subscribeLimitTime_
        );
    }

    function subscribe(uint256 stock) public nonReentrant whenNotPaused {
        require(stock > 0, "cannot be less than zero");
        require(financingShare * 2 > totalSold, "sold out"); //Sold out
        require(subscribeTime > 0, "UnStart subscribe"); //Not turned on
        require(stock <= subscribeMax, "subscribe limit");
        require(
            user[_msgSender()].amount <= userMax,
            "user total subscribe limit"
        );

        require(
            subscribeTime + subscribeLimitTime > block.timestamp,
            "time expired"
        );
        require(stock > 0, "Not yet subscribed"); //Quantity greater than 0

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

    //Refund subscribed by the user
    function unSubscribe(
        uint256 expire,
        bytes memory signature
    ) public whenNotPaused nonReentrant {
        require(user[_msgSender()].exist == true, "company  does not exist"); //The user does not exist
        require(user[_msgSender()].unStake == false, "company  does not exist"); //

        bytes32 msgSplice = keccak256(
            abi.encodePacked(_msgSender(), expire, address(this), "dfb08b8d")
        );

        _checkRole(
            PLATFORM_ROLE,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );

        user[_msgSender()].unStake = true;
        uint256 amount = user[_msgSender()].amount * stakeSharePrice;
        usdt.safeTransfer(_msgSender(), amount);
        emit unSubscribeLog(_msgSender(), amount, block.timestamp);
    }

    function minerStake(
        uint256 stakeAmount,
        uint256 expire,
        bytes memory signature
    ) public nonReentrant whenNotPaused {
        require(expire > block.timestamp, "not yet expired");
        require(stakeMiner[_msgSender()].exist == true, "No intention payment");
        require(stakeMiner[_msgSender()].hadStaked == false, "Already staked"); //Participated
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
            PLATFORM_ROLE,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );
        usdt.safeTransferFrom(_msgSender(), address(this), stakeAmount);
        stakeMiner[_msgSender()].stakeAmount = stakeAmount;
        stakeMiner[_msgSender()].hadStaked = true;
        emit minerStakeLog(_msgSender(), stakeAmount, block.timestamp);
    }

    function unMinerStake(
        uint256 expire,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public nonReentrant {
        require(
            stakeMiner[_msgSender()].exist == true,
            "miner  does not exist"
        ); //
        require(stakeMiner[_msgSender()].nonce == nonce, "nonce invalid"); //
        require(
            stakeMiner[_msgSender()].stakeAmount >= amount && amount > 0,
            "amount invalid"
        );
        require(expire > block.timestamp, "not yet expired"); //
        bytes32 msgSplice = keccak256(
            abi.encodePacked(
                address(this),
                "15cababe",
                _msgSender(),
                expire,
                amount,
                nonce
            )
        );
        _checkRole(
            PLATFORM_ROLE,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );
        stakeMiner[_msgSender()].stakeAmount -= amount;
        stakeMiner[_msgSender()].nonce += 1;
        usdt.safeTransfer(_msgSender(), amount);
        emit unMinerStakeLog(_msgSender(), amount, block.timestamp);
    }

    //Program staking
    function planStake(
        companyType role,
        uint256 totalAmount,
        uint256 stakeAmount,
        uint256 expire,
        bytes memory signature
    ) public nonReentrant whenNotPaused {
        require(expire > block.timestamp, "not yet expired"); //It hasn't expired yet
        require(companyList[role].exist == false, "participated"); //Participated
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
            PLATFORM_ROLE,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );
        companyList[role].totalAmount = totalAmount;
        companyList[role].stakeAmount = stakeAmount;
        companyList[role].exist = true;
        companyList[role].addr = _msgSender();
        usdt.safeTransferFrom(_msgSender(), address(this), stakeAmount);
        emit planStakeLog(_msgSender(), stakeAmount, block.timestamp, role);
    }

    //Refund stake
    function unPlanStake(
        companyType role
    ) public nonReentrant onlyRole(ADMIN_ROLE) {
        require(companyList[role].exist == true, "company  does not exist"); //The user does not exist
        require(
            companyList[role].unStake == false,
            "cannot be repeated unStake"
        );
        companyList[role].unStake = true;
        usdt.safeTransfer(
            companyList[role].addr,
            companyList[role].stakeAmount
        );
        emit unPlanStakeLog(
            companyList[role].addr,
            companyList[role].stakeAmount,
            block.timestamp,
            role
        );
    }

    function transferAmount(uint256 amount) public {
        require(financAddr != address(0), "address is null");
        require(_msgSender() == financAddr, "only invoke by owner");
        usdt.transfer(financAddr, amount);
    }

    function StakeAmount(address account) public view returns (uint256) {
        return stakeMiner[account].stakeAmount;
    }

    function setFinancing(address addr) public onlyRole(PLATFORM_ROLE) {
        require(addr.isContract(), "addr must Contract address");
        financAddr = addr;
    }

    //todo returns staking minerStake
    function IntentMoneyAmount(
        address account,
        uint256 id
    ) public view returns (uint256) {
        return miner[account][id].amount;
    }

    //Check the subscription amount
    function viewSubscribe(address account) public view returns (uint256) {
        return user[account].amount;
    }

    function pause() public whenNotPaused onlyRole(PLATFORM_ROLE) {
        _pause();
    }

    function unpause() public whenPaused onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function payDD() public onlyRole(ADMIN_ROLE) {
        require(isPayDD == false, "It can only be called once");
        usdt.safeTransfer(DDAddr, ddFee);
        isPayDD = true;
        emit payDDLog(DDAddr, ddFee, block.timestamp);
    }

    //Pay the miner's pledge deposit to the SPV
    function payMinerToSpv(
        uint256 amount,
        uint256 expire,
        bytes memory signature
    ) public onlyRole(ADMIN_ROLE) {
        require(amount >= 0, "address is null"); //Not equal to zero
        require(isPayMinerToSpv == false, "already paid"); //Already paid
        bytes32 msgSplice = keccak256(
            abi.encodePacked(address(this), "4afc651e", amount, expire)
        );
        _checkRole(
            PLATFORM_ROLE,
            ECDSA.recover(ECDSA.toEthSignedMessageHash(msgSplice), signature)
        );
        isPayMinerToSpv = true;
        usdt.safeTransfer(spvAddr, amount);
        emit payMinerToSpvLog(spvAddr, amount, block.timestamp);
    }

    //Emergency withdrawals
    function withdraw(
        uint256 amount,
        address addr
    ) public onlyRole(EMERGENCY_ROLE) {
        usdt.safeTransfer(addr, amount);
    }

    function isParticipated(
        address account,
        uint256 id
    ) public view returns (bool) {
        return miner[account][id].exist;
    }
}
