const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");
const NFTImpl = artifacts.require("ERC1155SImpl");
const ethers = require("ethers");
var tools = require('../tools/web3-utils');




contract("FinancingTest-whilepay", (accounts) => {

    let user = accounts[4]
    before(async function () {
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        //transfer usdt
        console.log(`\n using account ${user} as user ! `)
        const result = await usdt.transfer(user, web3.utils.toWei('100000', 'ether'))
        assert.equal(result.receipt.status, true, "transfer usdt failed !");
        const balance = await usdt.balanceOf(user)
        console.log(` ${user} ${web3.utils.fromWei(balance, 'ether')} USDT \n`)

        //startSubscribe 
        // uint256 financingShare_,
        // uint256 stakeSharePrice_,
        // uint256 subscribeTime_,
        // uint256 subscribeLimitTime_
        let subBegin = await bid.startSubscribe(10000, 20, 1689581119, 1689753919);
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

        let resultApprove = await usdt.approve(bid.address, web3.utils.toWei(web3.utils.toBN(stock * stakeSharePrice), 'ether'), { from: user })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

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

        const whitelistPaymentTime =await financing.whitelistPaymentTime()
        console.log(`whitelistPaymentTime ${whitelistPaymentTime}`)

        const result = await financing.whiteListPayment({ from: user })
        tools.printfLogs(result)

        
    })


})