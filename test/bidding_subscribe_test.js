const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
var tools = require('../tools/web3-utils');

contract("BiddingTest-subscribe", (accounts) => {
    let user = accounts[4]

    before(async function () {
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        //transfer usdt
        await tools.transferUSDT(usdt,accounts[0],user,'100000')

        //startSubscribe 
        // uint256 financingShare_,
        // uint256 stakeSharePrice_,
        // uint256 subscribeTime_,
        // uint256 subscribeLimitTime_ 10000
        const financingShare_ = await tools.USDTToWei(usdt,'10000')
        const stakeSharePrice_ = await tools.USDTToWei(usdt,'20')
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

        
        let resultApprove = await usdt.approve(bid.address, await tools.USDTToWei(usdt,stock * stakeSharePrice), { from: user })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        let sub = await bid.subscribe(10, { from: user })
        assert.equal(sub.receipt.status, true, "subscribe failed !");

        let totalSold1 = await bid.totalSold()
        let Subscribed = await bid.viewSubscribe(user)

        assert.equal(stock, Subscribed, "stock != stock");
        assert.equal(totalSold1, stock, "totalSold1 != stock");

        console.log(`after totalSold = ${totalSold1}`)



        console.log(`logs: ${JSON.stringify(sub.receipt.logs, null, 3)}`)
    });

    it("testing unSubscribe() should assert true", async function () {
        //subscribe
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        // Date().Add()
        let expire = 1689753919

        //sign message
        let digest = ethers.solidityPackedKeccak256(["address", "uint256", "address", "string"], [user, expire, bid.address, tools.getsignature(bid, 'unSubscribe')])
        console.log(`digest : ${digest}`)

        console.log(`owner ${accounts[0]}`)
        let signature = await web3.eth.sign(digest, accounts[0])
        // console.log(`signed: ${msg}`)

        signature = signature.substr(0, 130) + (signature.substr(130) == "00" ? "1b" : "1c");

        //recover
        const recover = web3.eth.accounts.recover(digest, signature)
        expect(recover).to.equal(accounts[0])
        console.log(`recover : ${recover}`)

        let sub = await bid.unSubscribe(expire, signature, { from: user })
        assert.equal(sub.receipt.status, true, "unSubscribe failed !");

        let totalSold1 = await bid.totalSold()
        // assert.equal(totalSold1, stock, "totalSold1 != stock");

        console.log(`after totalSold = ${totalSold1}`)

        console.log(`logs: ${JSON.stringify(sub.receipt.logs, null, 3)}`)
    });
})