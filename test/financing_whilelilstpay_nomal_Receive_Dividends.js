const Web3 = require('web3');
const Dividends = artifacts.require("Operation");
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

    it("testing checkDone should assert true", async function () {
        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed();
        const tx = await financing.checkDone()
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
        const tx = await dividends.income(amount, { from: user1 })
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
        const ids = await nft.nftBalance(shareNFT, user)

        console.log(ids)
        const tx = await dividends.receiveDividends(0, ids, { from: user })
        assert.equal(tx.receipt.status, true, "receiveDividends failed !");
        console.log(`receiveDividends hash ${tx.tx}`)

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

    const spvReceive = async function () {

        const caller = accounts[2]
        const financing = await Financing.deployed()
        const dividends = await Dividends.at(await financing.dividends());
        const usdt = await USDTTest.deployed();
        //addrType.spvAddr
        const addrType = await dividends.addrType()
        const spvBalance = await tools.balanceOF(usdt.address, addrType.spvAddr)
        const feeType = await dividends.feeType()
        const tx = await dividends.spvReceive({ from: caller })
        console.log(`spvReceive tx ${tx.tx}`)
        const spvStartTime = await dividends.spvStartTime()
        console.log(`spvStartTime ${spvStartTime}`)

        //feeType.spvFee
        // await tools.AssertUSDT(usdt.address, addrType.spvAddr, feeType.spvFee.add(spvBalance))

    }
    it("testing spvReceive() should assert true", spvReceive)
    it("testing spvReceiveTry() should assert true", async function () {
        try {
            await spvReceive()
        } catch (error) {
            assert(error.message.includes("Refusal to contract transactions"), "Expected an error with message 'Error message'.");
        }
    })

    it("testing spvReceive2Year() should assert true", async function () {
        const financing = await Financing.deployed()
        const dividends = await Dividends.at(await financing.dividends());
        //limitTimeType.spvIntervalTime
        const limitTimeType = await dividends.limitTimeType();
        await tools.timeout(new BN(limitTimeType.spvIntervalTime).toNumber() * 1000 + 2000)
        await spvReceive()
    })

    const electrStake = async function () {
        const electrStakeAddr = accounts[2];
        //addrType.electrStakeAddr, feeType.electrStakeFee
        const financing = await Financing.deployed()
        const dividends = await Dividends.at(await financing.dividends());
        const usdt = await USDTTest.deployed();

        const addrType = await financing.addrType()

        const feeType = await financing.feeType()
        const orgBalance = await tools.balanceOF(usdt.address, addrType.electrStakeAddr)
        const electrStake = await dividends.electrStake({ from: electrStakeAddr })
        assert.equal(electrStake.receipt.status, true, "electrStake failed !");
        console.log(`electrStake hash ${electrStake.tx}`)

        tools.AssertUSDT(usdt.address, addrType.electrStakeAddr, feeType.electrStakeFee.add(orgBalance))
    }
    //electrStake()
    it("testing electrStake() should assert true", electrStake)

    it("testing electrStake2() should assert true", async function () {
        try {
            await electrStake()
        } catch (error) {
            assert(error.message.includes("You have claimed it"), "Expected an error with message 'Error message'.");
        }
    })

    const energyReceive = async function () {
        await tools.timeout(7000)

        const electrAddr = accounts[2];

        const financing = await Financing.deployed()
        const dividends = await Dividends.at(await financing.dividends());
        const usdt = await USDTTest.deployed()

        const wei = await tools.USDTFromWei(usdt, await tools.balanceOF(usdt.address, financing.address))
        console.log(`contract balance of ${wei}`)

        const addrType = await financing.addrType()
        const feeType = await financing.feeType()
        const limitTimeType = await financing.limitTimeType()

        const electrStartTime = await financing.electrStartTime()
        console.log(`electrStartTime ${electrStartTime}`)
        // const origPlatformFeeAddrBalance = await tools.balanceOF(usdt.address, platformFeeAddr)
        //addrType.builderAddr
        // 判断第一次领取 需要质押电力
        // uint256 months = (block.timestamp - electrStartTime) /
        //     limitTimeType.electrIntervalTime;
        // uint256 amount = months * feeType.electrFee;
        // electrStartTime += months * limitTimeType.electrIntervalTime;
        // // 判断第一次押金
        // usdt.safeTransfer(addrType.electrAddr, amount);


        const origbuilderAddrBalance = await tools.balanceOF(usdt.address, addrType.builderAddr)

        console.log(`feeType.electrFee ${feeType.electrFee}`)
        console.log(`limitTimeType.electrIntervalTime ${limitTimeType.electrIntervalTime}`)

        const electrStake = await dividends.energyReceive({ from: electrAddr })
        assert.equal(electrStake.receipt.status, true, "electrStake failed !")
        console.log(`energyReceive tx ${electrStake.tx}`)

        // const origbuilderAddrBalance = await tools.balanceOF(usdt.address, addrType.builderAddr)
        // await tools.AssertUSDT(usdt.address, addrType.electrAddr, feeType.electrFee.add(origbuilderAddrBalance))
        // await tools.AssertUSDT(usdt.address, platformFeeAddr, feeType.feeType.publicSalePlatformFee.add(origPlatformFeeAddrBalance))
    }
    //energyReceive
    it("testing energyReceive() should assert true", energyReceive)

    const insuranceReceive = async function () {

        const insuranceAddr = accounts[4];
        // usdt.safeTransfer(addrType.builderAddr, feeType.remainBuildFee);
        // usdt.safeTransfer(platformFeeAddr, feeType.publicSalePlatformFee);
        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed()
        const dividends = await Dividends.at(await financing.dividends());

        const addrType = await financing.addrType()
        const feeType = await financing.feeType()

        //addrType.insuranceAddr
        const origbuilderAddrBalance = await tools.balanceOF(usdt.address, addrType.insuranceAddr)
        const electrStake = await dividends.insuranceReceive({ from: insuranceAddr })
        assert.equal(electrStake.receipt.status, true, "electrStake failed !");
        // await tools.AssertUSDT(usdt.address, addrType.insuranceAddr, feeType.insuranceFee.add(origbuilderAddrBalance))
    }

    //insuranceReceive
    it("testing insuranceReceive() should assert true", insuranceReceive)

    it("testing insuranceReceiveTry() should assert true", async function () {
        try {
            await insuranceReceive()
        } catch (error) {
            assert(error.message.includes("Refusal to contract transactions"), "Expected an error with message 'Error message'.");
        }
    })

    const trustManagementReceive = async function () {
        const trustAddr = accounts[5];
        const financing = await Financing.deployed()
        const usdt = await USDTTest.deployed()
        const dividends = await Dividends.at(await financing.dividends());

        const addrType = await financing.addrType()
        const feeType = await financing.feeType()

        console.log(`trustAddr = ${addrType.trustAddr}`)
        //addrType.insuranceAddr
        const origbuilderAddrBalance = await tools.balanceOF(usdt.address, addrType.trustAddr)
        const electrStake = await dividends.trustManagementReceive({ from: trustAddr })
        assert.equal(electrStake.receipt.status, true, "electrStake failed !");
        console.log(`trustManagementReceive tx ${electrStake.tx}`)
    }

    it("testing trustManagementReceive() should assert true", trustManagementReceive)
})