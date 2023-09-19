const Web3 = require('web3');
const BN = require('bn.js');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");
const ethers = require("ethers");
const tools = require('../tools/web3-utils');
const nft = require('../tools/nft');

const ActionChoices = {
    INIT: 0,
    whitelistPayment: 1, // 白名单
    publicSale: 2, // 公售
    publicSaleFailed: 3, // 公售失败
    startBuild: 4, // 开始建造
    remainPayment: 5, // 尾款
    Bargain: 6, // 捡漏
    FINISH: 7, // 完成
    FAILED: 8 // 失败
}


contract("FinancingTest-PublicSale-1-remain-fail", (accounts) => {

    let user = accounts[5]

    before(async function () {
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();
        const financing = await Financing.deployed()
        const shareType = await financing.shareType()

        await tools.transferUSDT(usdt, accounts[0], user, '900000')

        await tools.transferUSDT(usdt, accounts[0], financing.address, '10')

        //startSubscribe 
        // uint256 financingShare_,
        // uint256 stakeSharePrice_,
        // uint256 subscribeTime_,
        // uint256 subscribeLimitTime_
        console.log(`sharePrice ${shareType.stakeSharePrice}`)
        let subBegin = await bid.startSubscribe(100, shareType.stakeSharePrice, 1694161282, 1695267313);
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
        console.log(`stock ${stock}`)
        let resultApprove = await usdt.approve(bid.address, stakeSharePrice.mul(tools.toBN(stock)), { from: user })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        await tools.printUSDT(usdt, user)

        let sub = await bid.subscribe(stock, { from: user })
        assert.equal(sub.receipt.status, true, "subscribe failed !");

        let totalSold1 = await bid.totalSold()
        let Subscribed = await bid.viewSubscribe(user)

        assert.equal(stock, Subscribed, "stock != stock");
        assert.equal(totalSold1, stock, "totalSold1 != stock");

        console.log(`after totalSold = ${totalSold1}`)
    });

    it("testing whiteListPayment() should assert true", async function () {

        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();

        let resultApprove = await usdt.approve(Financing.address, await tools.USDTToWei(usdt, '10000'), { from: user })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        const whitelistPaymentTime = await financing.whitelistPaymentTime()
        console.log(`whitelistPaymentTime ${whitelistPaymentTime}`)

        const result = await financing.whiteListPayment({ from: user })
        assert.equal(result.receipt.status, true, "whiteListPayment failed !");

    })


    //checkWhiteList()
    //publicSaleTotalSold < shareType.financingShare
    it("testing checkWhiteList() should assert true", async function () {

        const financing = await Financing.deployed()

        const checkWhiteList = await financing.checkWhiteList()
        assert.equal(checkWhiteList.receipt.status, true, "checkWhiteList failed !");

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
        if (schedule == ActionChoices.publicSale) {
            console.log(`public sale open`)
        }
        if (schedule == ActionChoices.publicSaleFailed) {
            console.log(`public publicSaleFailed`)
        }
    })


    it("testing publicSale() should assert true", async function () {

        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();
        const bid = await BiddingTest.deployed();

        const amount_ = 2
        const share = await financing.shareType()

        const mAmount = tools.toBN(amount_).mul(share.firstSharePrice.sub(share.stakeSharePrice));
        console.log(`approve amount ${mAmount}`)

        let resultApprove = await usdt.approve(Financing.address, mAmount, { from: user })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        const publicSaleTotalSold = await financing.publicSaleTotalSold()
        console.log(`publicSaleTotalSold ${publicSaleTotalSold}`)

        await tools.printUSDT(usdt, bid.address)

        const pub = await financing.publicSale(amount_, { from: user })
        assert.equal(pub.receipt.status, true, "publicSale failed !");


        const receiptNFT = await financing.receiptNFT()
        const balance = await nft.balanceOf(receiptNFT, user)
        console.log(`user ${balance.toString()} user addr ${user}`)
        console.log(`final ${financing.address}`)
        expect(balance.toString()).to.equal('12')

        for (let index = 1; index <= balance.toNumber(); index++) {
            const ownner = await nft.ownerOf(receiptNFT, 1)
            expect(ownner).to.equal(user)
        }

        let schedule = await financing.schedule()
        console.log(`schedule : ${schedule}`)

        const publicSaleTotalSold1 = await financing.publicSaleTotalSold()
        console.log(`publicSaleTotalSold ${publicSaleTotalSold1} ${share.financingShare}`)

    })

    it("testing checkPublicSale() should assert true", async function () {

        const financing = await Financing.deployed()

        const publicSaleTotalSold = await financing.publicSaleTotalSold()
        console.log(`publicSaleTotalSold ${publicSaleTotalSold}`)

        //publicSaleTime + limitTimeType.publicSaleLimitTime
        const publicSaleTime = await financing.publicSaleTime()
        const limitTimeType = await financing.limitTimeType()
        console.log(`limitTimeType ${limitTimeType.publicSaleLimitTime}`)
        await tools.timeout(60000)

        const pub = await financing.checkPublicSale()
        assert.equal(pub.receipt.status, true, "checkPublicSale failed !");

        let schedule = await financing.schedule()
        console.log(`schedule : ${schedule}`)

        const publicSaleTotalSold1 = await financing.publicSaleTotalSold()
        console.log(`publicSaleTotalSold ${publicSaleTotalSold1} ${schedule.financingShare}`)

    })

    it("testing redeemPublicSale() should assert true", async function () {
        const financing = await Financing.deployed()
        const receiptNFT = await financing.receiptNFT()
        const bid = await BiddingTest.deployed();

        const usdt = await USDTTest.deployed();
        const ids = await nft.nftBalance(receiptNFT, user)
        console.log(ids)
        await tools.printUSDT(usdt, financing.address)
        await tools.printUSDT(usdt, bid.address)
        const tx = await financing.redeemPublicSale(ids, { from: user })
        assert.equal(tx.receipt.status, true, "publicSale failed !");
    })

})