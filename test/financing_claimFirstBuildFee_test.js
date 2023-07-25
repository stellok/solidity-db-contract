const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");
const ethers = require("ethers");
var tools = require('../tools/web3-utils');


contract("FinancingTest-claimFirstBuildFee", (accounts) => {


    before(async function () {
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        //transfer usdt
        console.log(`\n using account ${user} as user ! `)
        const amount = await tools.USDTToWei(usdt, '100000')
        const result = await usdt.transfer(user, amount)
        assert.equal(result.receipt.status, true, "transfer usdt failed !");
        const balance = await usdt.balanceOf(user)
        console.log(` ${user} ${web3.utils.fromWei(balance, 'ether')} USDT \n`)

    });

    it("testing claimFirstBuildFee() should assert true", async function () {
        const instance = await Financing.deployed();
        await instance.claimFirstBuildFee();
    })

})