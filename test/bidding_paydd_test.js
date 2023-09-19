const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
const tools = require('../tools/web3-utils');

contract("BiddingTest-paydd", (accounts) => {

    let user = accounts[5]

    before(async function () {
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();
        //transfer usdt
        console.log(`\n using account ${user} as user ! `)
        const amount = await tools.USDTToWei(usdt, '100000')
        const result = await usdt.transfer(user,amount)
        assert.equal(result.receipt.status, true, "transfer usdt failed !");
        const balance = await usdt.balanceOf(user)
        console.log(` ${user} ${await tools.USDTFromWei(usdt,balance)} USDT \n`)

    });

    it("testing payDDFee() should assert true", async function () {

        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();
        //get ddFee
        const ddFee = await bid.ddFee()
        let resultApprove = await usdt.approve(bid.address, ddFee)
        assert.equal(resultApprove.receipt.status, true, "approve failed !");
        const isddFee = await bid.isfDdFee()
        expect(isddFee).to.equal(false)
        // console.log(`approve ${JSON.stringify(resultApprove.receipt)}`)
        let result = await bid.payDDFee();
        assert.equal(result.receipt.status, true, "payDDFee failed !");
        // console.log(`result ${result.receipt}`)
        let balanceOf = await usdt.balanceOf(bid.address);
        console.log(`balanceOf usdt bid contract ${balanceOf}`)
        assert.equal(balanceOf.toString(), ddFee.toString(), "balanceOf must == ddFee");

    });

    const refundDDFee = async function () {

        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();
        //get ddFee
        const ddFee = await bid.ddFee()
        const isddFee = await bid.isfDdFee()
        expect(isddFee).to.equal(true)
        let result = await bid.refundDDFee();
        assert.equal(result.receipt.status, true, "refundDDFee failed !");
        await tools.AssertUSDT(usdt.address, bid.address, '0')
    }

    it("testing refundDDFee() should assert true", refundDDFee);

    it("testing refundDDFee() should assert true", async function () {
        
    });

})