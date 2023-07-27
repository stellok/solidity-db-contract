const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
const tools = require('../tools/web3-utils');

contract("BiddingTest-payMinerToSpv", (accounts) => {

    let user = accounts[5]

    before(async function () {

        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();
        await tools.transferUSDT(usdt, accounts[0], user, '1000000')
        await tools.transferUSDT(usdt, accounts[0], bid.address, '1000000')

    });

    it("testing payMinerToSpv() should assert true", async function () {

        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        // uint256 amount,
        // uint256 expire,
        // bytes memory signature
        const amount = await tools.USDTToWei(usdt, '10000')

        const expire = 1690616038
        // address(this),
        // "4afc651e",
        // amount,
        // expire
        const digest = ethers.solidityPackedKeccak256(["address", "string", "uint256", "uint256"], [bid.address, tools.getsignature(bid, 'payMinerToSpv'), amount.toString(), expire])
        console.log(`digest : ${digest}`)

        console.log(`owner ${accounts[0]}`)
        let signature = await web3.eth.sign(digest, accounts[0])

        signature = signature.substr(0, 130) + (signature.substr(130) == "00" ? "1b" : "1c");

        const tx = await bid.payMinerToSpv(amount, expire, signature)
        assert.equal(tx.receipt.status, true, "approve failed !");

        const spvAddr  = await bid.spvAddr()
        await tools.AssertUSDT(usdt.address,spvAddr,amount)
    });


})