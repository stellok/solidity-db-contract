const Web3 = require('web3');
const Dividends = artifacts.require("Dividends");
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");
const ethers = require("ethers");
const tools = require('../tools/web3-utils');
const nft = require('../tools/nft');
const axios = require('axios');
const BN = require('bn.js');

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


contract("FinancingTest-whilepay-Dividends-Receive", (accounts) => {

    axios.defaults.baseURL = 'http://192.168.1.115:8088';

    let user1 = accounts[5]

    let user2 = accounts[6]
    let user3 = accounts[7]
    let user4 = accounts[7]

    let user = accounts[5]


    before(async function () {
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        await tools.transferUSDT(usdt, accounts[0], user, '1000000')

        await tools.transferUSDT(usdt, accounts[0], user1, '1000000')
        await tools.transferUSDT(usdt, accounts[0], user2, '1000000')
        await tools.transferUSDT(usdt, accounts[0], user3, '1000000')
        await tools.transferUSDT(usdt, accounts[0], user4, '1000000')
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

    it("testing subscribe1() should assert true", async function () {
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

        let sub = await bid.subscribe(stock, { from: user })
        assert.equal(sub.receipt.status, true, "subscribe failed !");

        let totalSold1 = await bid.totalSold()
        let Subscribed = await bid.viewSubscribe(user)

        assert.equal(stock, Subscribed.toNumber(), "stock != stock");
        assert.equal(totalSold1, stock, "totalSold1 != stock");

        console.log(`after totalSold = ${totalSold1}`)

    });

    it("testing subscribe2() should assert true", async function () {
        //subscribe
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        let stock = 10;

        let financingShare = await bid.financingShare();
        let stakeSharePrice = await bid.stakeSharePrice();
        let totalSold = await bid.totalSold();
        console.log(`before totalSold = ${totalSold}`)

        if (financingShare * 2 - totalSold < stock) {
            stock = financingShare * 2 - totalSold;
        }

        let resultApprove = await usdt.approve(bid.address, stakeSharePrice.mul(tools.toBN(stock)), { from: user2 })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        await tools.printUSDT(usdt, user2)

        let sub = await bid.subscribe(stock, { from: user2 })
        assert.equal(sub.receipt.status, true, "subscribe failed !");

        let totalSold1 = await bid.totalSold()
        let Subscribed = await bid.viewSubscribe(user2)

        assert.equal(stock, Subscribed.toNumber(), "stock != stock");

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
        assert.equal(result.receipt.status, true, "approve failed !");

        const schedule = await financing.schedule()
        expect(schedule.toNumber()).to.equal(ActionChoices.whitelistPayment)

        const shareType = await financing.shareType()
        const publicSaleTotalSold = await financing.publicSaleTotalSold()
        console.log(`publicSaleTotalSold ${publicSaleTotalSold} shareType.financingShare ${shareType.financingShare}`)
        //publicSaleTotalSold < shareType.financingShare
    })

    it("testing whiteListPayment2() should assert true", async function () {

        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();

        let resultApprove = await usdt.approve(Financing.address, await tools.USDTToWei(usdt, '10000'), { from: user2 })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        const whitelistPaymentTime = await financing.whitelistPaymentTime()
        console.log(`whitelistPaymentTime ${whitelistPaymentTime}`)

        const result = await financing.whiteListPayment({ from: user2 })
        assert.equal(result.receipt.status, true, "approve failed !");

        const schedule = await financing.schedule()
        expect(schedule.toNumber()).to.equal(ActionChoices.startBuild)

        const shareType = await financing.shareType()
        const publicSaleTotalSold = await financing.publicSaleTotalSold()
        console.log(`publicSaleTotalSold ${publicSaleTotalSold} shareType.financingShare ${shareType.financingShare}`)
        //publicSaleTotalSold < shareType.financingShare
    })

    it("testing claimFirstBuildFee() should assert true", async function () {

        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();

        const platformFeeAddr = await financing.platformFeeAddr()
        const platformFeeAddrBalanceOf = await tools.balanceOF(usdt.address, platformFeeAddr)

        tools.printUSDT(usdt, financing.address)

        const feeType = await financing.feeType()

        const total = feeType.firstBuildFee.add(feeType.publicSalePlatformFee).add(feeType.buildInsuranceFee)
        const totalUSDT = await tools.USDTFromWei(usdt, total)
        console.log(`contract total ${totalUSDT} USDT`)

        const tx = await financing.claimFirstBuildFee({ from: accounts[2] });
        assert.equal(tx.receipt.status, true, "claimFirstBuildFee failed !");

        const addrType = await financing.addrType()

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

        await tools.printUSDT(usdt, user)

        const schedule = await financing.schedule()
        expect(schedule.toNumber()).to.equal(ActionChoices.remainPayment)
    })


    it("testing remainPayment() should assert true", async function () {

        await tools.timeout(5000)

        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();

        //remainPaymentTime + limitTimeType.remainPaymentLimitTime
        const limitTimeType = await financing.limitTimeType()
        const remainPaymentTime = await financing.remainPaymentTime()
        console.log(remainPaymentTime.add(limitTimeType.remainPaymentLimitTime).toString())

        const receiptNFT = await financing.receiptNFT()
        const balance = await nft.balanceOf(receiptNFT, user)

        var ids = new Array()
        for (let index = 1; index <= balance; index++) {
            ids.push(index)
        }
        console.log(`token ids ${ids}`)

        const shareType = await financing.shareType()
        //
        //tokenIdList.length * shareType.remainSharePrice
        const amount = balance.mul(shareType.remainSharePrice)
        let resultApprove = await usdt.approve(financing.address, amount, { from: user })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        const remainPayment = await financing.remainPayment(ids, { from: user })
        assert.equal(remainPayment.receipt.status, true, "remainPayment failed !");

        //issuedTotalShare >= shareType.financingShare
        const issuedTotalShare = await financing.issuedTotalShare()
        console.log(`issuedTotalShare ${issuedTotalShare} financingShare ${shareType.financingShare}`)
        if (issuedTotalShare.gte(shareType.financingShare)) {
            console.log("ActionChoices.FINISH")
        }

    })

    it("testing remainPayment2() should assert true", async function () {

        await tools.timeout(5000)

        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();

        //remainPaymentTime + limitTimeType.remainPaymentLimitTime
        const limitTimeType = await financing.limitTimeType()
        const remainPaymentTime = await financing.remainPaymentTime()
        console.log(remainPaymentTime.add(limitTimeType.remainPaymentLimitTime).toString())

        const receiptNFT = await financing.receiptNFT()
        const balance = await nft.balanceOf(receiptNFT, user2)
        console.log(`remainPayment2 nft ${balance}`)
        var ids = new Array()
        for (let index = 11; index <= (balance.toNumber() + 10); index++) {
            ids.push(index)
        }
        console.log(`token ids ${ids}`)

        const shareType = await financing.shareType()
        //
        //tokenIdList.length * shareType.remainSharePrice
        const amount = balance.mul(shareType.remainSharePrice)
        let resultApprove = await usdt.approve(financing.address, amount, { from: user2 })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        const remainPayment = await financing.remainPayment(ids, { from: user2 })
        assert.equal(remainPayment.receipt.status, true, "remainPayment failed !");

        //issuedTotalShare >= shareType.financingShare
        const issuedTotalShare = await financing.issuedTotalShare()
        console.log(`issuedTotalShare ${issuedTotalShare} financingShare ${shareType.financingShare}`)
        if (issuedTotalShare.gte(shareType.financingShare)) {
            console.log("ActionChoices.FINISH")
        }

        const schedule = await financing.schedule()
        expect(schedule.toNumber()).to.equal(ActionChoices.FINISH)

    })
    //claimRemainBuildFee
    it("testing claimRemainBuildFee() should assert true", async function () {

        const builderAddr = accounts[2];
        //builderAddr

        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();
        //addrType.spvAddr

        // usdt.safeTransfer(addrType.builderAddr, feeType.remainBuildFee);
        // usdt.safeTransfer(platformFeeAddr, feeType.publicSalePlatformFee);

        const platformFeeAddr = await financing.platformFeeAddr()

        const addrType = await financing.addrType()
        const feeType = await financing.feeType()

        const origBalance = await tools.balanceOF(usdt.address, addrType.builderAddr)
        const origplatformFeeAddrBalance = await tools.balanceOF(usdt.address, platformFeeAddr)

        const tx = await financing.claimRemainBuildFee({ from: builderAddr })
        assert.equal(tx.receipt.status, true, "claimRemainBuildFee failed !");

        //feeType.spvFee
        await tools.AssertUSDT(usdt.address, addrType.builderAddr, feeType.remainBuildFee.add(origBalance))
        await tools.AssertUSDT(usdt.address, platformFeeAddr, feeType.publicSalePlatformFee.add(origplatformFeeAddrBalance))

    })

    it("testing checkDone should assert true", async function () {
        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();
        const financingFee_ = await tools.USDTToWei(usdt, '12')
        const tx = await financing.checkDone(financingFee_, accounts[7], 100000, 30)
        assert.equal(tx.receipt.status, true, "checkDone failed !");
        console.log(`tx ${tx.tx}`)
        const dividends = await financing.dividends()
        console.log(`dividends ${dividends}`)
        await axios.post('/cache/abi', { contract: dividends, abi: JSON.stringify(Dividends.abi) })
    })

    const payment = async function () {
        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();
        const dividends = await Dividends.at(await financing.dividends());
        const amount = await tools.USDTToWei(usdt, '1000')
        await tools.approve(usdt, dividends.address, amount, user1)
        const tx = await dividends.payment(amount, { from: user1 })
        console.log(`payment tx ${tx.tx}`)
        const lastExecuted = await dividends.lastExecuted()
        console.log((`lastExecuted ${lastExecuted}`))
    }

    it("testing payment() should assert true", payment)

    //doMonthlyTask
    it("testing doMonthlyTask() should assert true", async function () {
        const financing = await Financing.deployed()
        const dividends = await Dividends.at(await financing.dividends());
        const expire = await dividends.expire()
        console.log(`expire ${expire}`)
        await tools.timeout(new BN(expire).toNumber() * 1000 + 2000)

        const index = await dividends.phaseIndex()
        console.log(`index ${index}`)
        const lastExecuted = await dividends.lastExecuted()
        console.log((`lastExecuted ${lastExecuted}`))

        const tx = await dividends.doMonthlyTask(0, { from: user2 })
        assert.equal(tx.receipt.status, true, "doMonthlyTask failed !");
        console.log(`doMonthlyTask hash ${tx.tx}`)
    })

    it("testing payment_index() should assert true", payment)

    const receiveDividends = async function () {

        // await tools.timeout(22000)
        const financing = await Financing.deployed()
        const dividends = await Dividends.at(await financing.dividends());
        const lastExecuted = await dividends.lastExecuted()

        console.log((`lastExecuted ${lastExecuted}`))

        const shareNFT = await financing.shareNFT()
        console.log(`shareNFT ${shareNFT}`)
        const axios = require('axios');

        let config = {
            method: 'get',
            maxBodyLength: Infinity,
            url: 'http://192.168.1.115:8088/nft/list',
            headers: {
                'Content-Type': 'application/json'
            },
            data: JSON.stringify({
                "contract": shareNFT,
                "address": user
            })
        };

        const resp = await axios.request(config)
        const data = resp.data.data
        var ids = new Array()
        data.tokenIds.forEach(element => {
            ids.push(parseInt(element))
        });

        console.log(ids)
        const tx = await dividends.receiveDividends(0, ids, { from: user })
        assert.equal(tx.receipt.status, true, "receiveDividends failed !");
        console.log(`receiveDividends hash ${tx.tx}`)

        data.tokenIds.forEach(async element => {
            const b = await dividends.isReceive(0, element)
            assert.equal(b, true, "token is true");
        });
    }

    it("testing receiveDividends() should assert true", receiveDividends)


    //try again
    it("testing receiveDividends2() should assert true", async function () {
        try {
            await receiveDividends()
        } catch (error) {
            assert(error.message.includes("Cannot be claimed repeatedly"), "Expected an error with message 'Error message'.");
        }
    })


})