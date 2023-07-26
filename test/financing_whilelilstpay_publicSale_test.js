const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");
const ethers = require("ethers");
const tools = require('../tools/web3-utils');
const nft = require('../tools/nft');




contract("FinancingTest-whilepay", (accounts) => {

    let user = accounts[5]

    before(async function () {
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        await tools.transferUSDT(usdt, accounts[0], user, '1000000')

        //startSubscribe 
        // uint256 financingShare_,
        // uint256 stakeSharePrice_,
        // uint256 subscribeTime_,
        // uint256 subscribeLimitTime_
        const financingShare_ = await tools.USDTToWei(usdt, '1000')
        const stakeSharePrice_ = await tools.USDTToWei(usdt, '7')
        let subBegin = await bid.startSubscribe(financingShare_, stakeSharePrice_, 1689581119, 1689753919);
        assert.equal(subBegin.receipt.status, true, "startSubscribe failed !");
    });

    it("testing subscribe() should assert true", async function () {
        //subscribe
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        let stock = 10;

        let financingShare = await bid.financingShare();
        let stakeSharePrice = await bid.stakeSharePrice();
        let totalSold = await bid.totalSold();
        assert.equal(totalSold, 0, "totalSold == 0");
        console.log(`before totalSold = ${totalSold}`)

        if (financingShare * 2 - totalSold < stock) {
            stock = financingShare * 2 - totalSold;
        }

        let resultApprove = await usdt.approve(bid.address, stakeSharePrice.mul(tools.toBN(stock)), { from: user })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        await tools.printUSDT(usdt, user)

        let sub = await bid.subscribe(10, { from: user })
        assert.equal(sub.receipt.status, true, "subscribe failed !");

        let totalSold1 = await bid.totalSold()
        let Subscribed = await bid.viewSubscribe(user)

        assert.equal(stock, Subscribed, "stock != stock");
        assert.equal(totalSold1, stock, "totalSold1 != stock");

        console.log(`after totalSold = ${totalSold1}`)

        tools.printfLogs(sub)
    });

    it("testing whiteListPayment() should assert true", async function () {

        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();

        let resultApprove = await usdt.approve(Financing.address, web3.utils.toWei(web3.utils.toBN(10000), 'ether'), { from: user })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        const whitelistPaymentTime = await financing.whitelistPaymentTime()
        console.log(`whitelistPaymentTime ${whitelistPaymentTime}`)

        const result = await financing.whiteListPayment({ from: user })
        tools.printfLogs(result)


    })


    //checkWhiteList()

    it("testing checkWhiteList() should assert true", async function () {

        const financing = await Financing.deployed()

        const checkWhiteList = await financing.checkWhiteList()
        assert.equal(checkWhiteList.receipt.status, true, "checkWhiteList failed !");

        tools.printfLogs(checkWhiteList)

        // enum ActionChoices {
        //     INIT,
        //     whitelistPayment, // 白名单
        //     publicSale, // 公售
        //     publicSaleFailed, // 公售失败
        //     startBuild, // 开始建造
        //     remainPayment, // 尾款
        //     Bargain, // 捡漏
        //     FINISH, // 完成
        //     FAILED // 失败
        // }

        let schedule = await financing.schedule()
        if (schedule == 2) {
            console.log(`public sale open`)
        }
        if (schedule == 3) {
            console.log(`public publicSaleFailed`)
        }
    })


    it("testing publicSale() should assert true", async function () {

        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();

        const amount_ = 10
        const share = await financing.shareType()

        const mAmount = tools.toBN(amount_).mul(share.firstSharePrice.sub(share.stakeSharePrice));
        console.log(`approve amount ${mAmount}`)

        let resultApprove = await usdt.approve(Financing.address, mAmount, { from: user })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        const publicSaleTotalSold = await financing.publicSaleTotalSold()
        console.log(`publicSaleTotalSold ${publicSaleTotalSold}`)

        const pub = await financing.publicSale(amount_, { from: user })
        tools.printfLogs(pub)

        const receiptNFT = await financing.receiptNFT()
        const balance = await nft.balanceOf(receiptNFT, user)
        console.log(`user ${balance.toString()} user addr ${user}`)
        console.log(`final ${financing.address}`)
        expect(balance.toString()).to.equal('20')

        for (let index = 1; index <= balance.toNumber(); index++) {
            const ownner = await nft.ownerOf(receiptNFT, 1)
            expect(ownner).to.equal(user)
        }

        let schedule = await financing.schedule()
        console.log(`schedule : ${schedule}`)

        const publicSaleTotalSold1 = await financing.publicSaleTotalSold()
        console.log(`publicSaleTotalSold ${publicSaleTotalSold1} ${share.financingShare}`)

    })

    it("testing claimFirstBuildFee() should assert true", async function () {



        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();

        const platformFeeAddr = await financing.platformFeeAddr()
        const platformFeeAddrBalanceOf = await tools.balanceOF(usdt.address, platformFeeAddr)

        const tx = await financing.claimFirstBuildFee({ from: accounts[2] });
        tools.printfLogs(tx)

        const addrType = await financing.addrType()
        const feeType = await financing.feeType()

        // usdt.safeTransfer(addrType.builderAddr, feeType.firstBuildFee);
        // // 给平台打钱
        // usdt.safeTransfer(platformFeeAddr, feeType.publicSalePlatformFee);
        // // 打保险费
        // usdt.safeTransfer(
        //     addrType.buildInsuranceAddr,
        //     feeType.buildInsuranceFee
        // );

        await tools.AssertUSDT(usdt.address, addrType.builderAddr, feeType.firstBuildFee)
        await tools.AssertUSDT(usdt.address, platformFeeAddr, platformFeeAddrBalanceOf.add(feeType.publicSalePlatformFee))
        await tools.AssertUSDT(usdt.address, addrType.buildInsuranceAddr, feeType.buildInsuranceFee)
    })

    it("testing remainPayment() should assert true", async function () {
        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();
        // financing.remainPayment()
    })

})