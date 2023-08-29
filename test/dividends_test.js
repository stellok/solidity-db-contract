const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");
const ethers = require("ethers");
const Dividends = artifacts.require("Dividends");
var tools = require('../tools/web3-utils');


contract("Dividends-test", (accounts) => {

    // console.log(process.env)

    let user1 = accounts[5]
    let user2 = accounts[6]
    let user3 = accounts[7]
    let user4 = accounts[7]

    before(async function () {
        const usdt = await USDTTest.deployed();
        await tools.transferUSDT(usdt, accounts[0], user1, '1000000')
        await tools.transferUSDT(usdt, accounts[0], user2, '1000000')
        await tools.transferUSDT(usdt, accounts[0], user3, '1000000')
        await tools.transferUSDT(usdt, accounts[0], user4, '1000000')
    })

    it("testing payment() should assert true", async function () {
        const usdt = await USDTTest.deployed();
        const dividends = await Dividends.deployed();
        const amount = await tools.USDTToWei(usdt, '1000')
        await tools.approve(usdt, dividends.address, amount, user1)
        const tx = await dividends.payment(amount, { from: user1 })

        const lastExecuted = await dividends.lastExecuted()
        console.log((`lastExecuted ${lastExecuted}`))



    })
    //doMonthlyTask
    it("testing doMonthlyTask() should assert true", async function () {

        await tools.timeout(22000)

        const dividends = await Dividends.deployed();
        const lastExecuted = await dividends.lastExecuted()
        console.log((`lastExecuted ${lastExecuted}`))

        const tx = await dividends.doMonthlyTask(0, { from: user2 })
        assert.equal(tx.receipt.status, true, "doMonthlyTask failed !");
    })

    it("testing receiveDividends() should assert true", async function () {

        // await tools.timeout(22000)

        const dividends = await Dividends.deployed();
        const lastExecuted = await dividends.lastExecuted()
        console.log((`lastExecuted ${lastExecuted}`))
        const ids = [1, 2, 3]
        const tx = await dividends.receiveDividends(0, ids, { from: user2 })
        assert.equal(tx.receipt.status, true, "receiveDividends failed !");
    })

        // it("testing spvReceive() should assert true", async function () {

    //     const caller = accounts[2]

    //     const financing = await Financing.deployed()
    //     const usdt = await USDTTest.deployed();
    //     //addrType.spvAddr
    //     const addrType = await financing.addrType()

    //     const spvBalance = await tools.balanceOF(usdt.address, addrType.spvAddr)

    //     const feeType = await financing.feeType()
    //     const tx = await financing.spvReceive({ from: caller })

    //     //feeType.spvFee
    //     await tools.AssertUSDT(usdt.address, addrType.spvAddr, feeType.spvFee.add(spvBalance))

    // })

    // //electrStake()
    // it("testing electrStake() should assert true", async function () {

    //     const electrStakeAddr = accounts[2];

    //     //addrType.electrStakeAddr, feeType.electrStakeFee
    //     const financing = await Financing.deployed()
    //     const usdt = await USDTTest.deployed();

    //     const addrType = await financing.addrType()

    //     const feeType = await financing.feeType()
    //     const orgBalance = await tools.balanceOF(usdt.address, addrType.electrStakeAddr)

    //     const electrStake = await financing.electrStake({ from: electrStakeAddr })
    //     assert.equal(electrStake.receipt.status, true, "electrStake failed !");

    //     tools.AssertUSDT(usdt.address, addrType.electrStakeAddr, feeType.electrStakeFee.add(orgBalance))
    // })

    // //energyReceive
    // it("testing energyReceive() should assert true", async function () {


    //     await tools.timeout(7000)

    //     const electrAddr = accounts[2];

    //     const financing = await Financing.deployed()
    //     const usdt = await USDTTest.deployed()

    //     const wei = await tools.USDTFromWei(usdt, await tools.balanceOF(usdt.address, financing.address))
    //     console.log(`contract balance of ${wei}`)

    //     const addrType = await financing.addrType()
    //     const feeType = await financing.feeType()
    //     const limitTimeType = await financing.limitTimeType()

    //     const electrStartTime = await financing.electrStartTime()
    //     console.log(`electrStartTime ${electrStartTime}`)
    //     // const origPlatformFeeAddrBalance = await tools.balanceOF(usdt.address, platformFeeAddr)
    //     //addrType.builderAddr
    //     // 判断第一次领取 需要质押电力
    //     // uint256 months = (block.timestamp - electrStartTime) /
    //     //     limitTimeType.electrIntervalTime;
    //     // uint256 amount = months * feeType.electrFee;
    //     // electrStartTime += months * limitTimeType.electrIntervalTime;
    //     // // 判断第一次押金
    //     // usdt.safeTransfer(addrType.electrAddr, amount);


    //     const origbuilderAddrBalance = await tools.balanceOF(usdt.address, addrType.builderAddr)

    //     console.log(`feeType.electrFee ${feeType.electrFee}`)
    //     console.log(`limitTimeType.electrIntervalTime ${limitTimeType.electrIntervalTime}`)

    //     const electrStake = await financing.energyReceive({ from: electrAddr })
    //     assert.equal(electrStake.receipt.status, true, "electrStake failed !")

    //     await tools.printfLogs(electrStake)

    //     // const origbuilderAddrBalance = await tools.balanceOF(usdt.address, addrType.builderAddr)
    //     // await tools.AssertUSDT(usdt.address, addrType.electrAddr, feeType.electrFee.add(origbuilderAddrBalance))
    //     // await tools.AssertUSDT(usdt.address, platformFeeAddr, feeType.feeType.publicSalePlatformFee.add(origPlatformFeeAddrBalance))
    // })

    // //insuranceReceive
    // it("testing insuranceReceive() should assert true", async function () {

    //     const insuranceAddr = accounts[4];

    //     // usdt.safeTransfer(addrType.builderAddr, feeType.remainBuildFee);
    //     // usdt.safeTransfer(platformFeeAddr, feeType.publicSalePlatformFee);
    //     const financing = await Financing.deployed()
    //     const usdt = await USDTTest.deployed()

    //     const addrType = await financing.addrType()
    //     const feeType = await financing.feeType()

    //     //addrType.insuranceAddr
    //     const origbuilderAddrBalance = await tools.balanceOF(usdt.address, addrType.insuranceAddr)

    //     const electrStake = await financing.insuranceReceive({ from: insuranceAddr })
    //     assert.equal(electrStake.receipt.status, true, "electrStake failed !");

    //     await tools.AssertUSDT(usdt.address, addrType.insuranceAddr, feeType.insuranceFee.add(origbuilderAddrBalance))
    // })

})