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
})