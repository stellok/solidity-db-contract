const Web3 = require('web3');
const nftSwap = artifacts.require("NFTMarket");
const NFTImpl = artifacts.require("NFT721Impl");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
const tools = require('../tools/web3-utils');

contract("nft721_nftswap_test", (accounts) => {

    let user = accounts[5]

    before(async function () {
        // const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        // //transfer usdt
        // console.log(`\n using account ${user} as user ! `)
        const amount = await tools.USDTToWei(usdt, '100000')
        const result = await usdt.transfer(user, amount)
        assert.equal(result.receipt.status, true, "transfer usdt failed !");
        // const balance = await usdt.balanceOf(user)
        // console.log(` ${user} ${await tools.USDTFromWei(usdt,balance)} USDT \n`)
        const swap = await nftSwap.deployed();
        const nft = await NFTImpl.deployed();
        const tx = await nft.mint(accounts[2], 10);
        assert.equal(tx.receipt.status, true, "mint failed !");

    });


    it("testing list() should assert true", async function () {

        const usdt = await USDTTest.deployed();
        const swap = await nftSwap.deployed();
        const nft = await NFTImpl.deployed();
        const tx = await nft.approve(swap.address, 1, { from: accounts[2] })
        assert.equal(tx.receipt.status, true, "approve failed !");
        const listTx = await swap.list(nft.address, 1, await tools.USDTToWei(usdt, 1), { from: accounts[2] })
        assert.equal(listTx.receipt.status, true, "list failed !");

    });

    it("testing purchase() should assert true", async function () {

        const usdt = await USDTTest.deployed();
        const swap = await nftSwap.deployed();
        const nft = await NFTImpl.deployed();

        const order = await swap.inOrder(nft.address, 1)
        console.log(order)

        //
        const ap = await usdt.approve(swap.address, order.price, { from: user })
        assert.equal(ap.receipt.status, true, "approve failed !");

        const buyTx = await swap.purchase(nft.address, 1, { from: user })
        assert.equal(buyTx.receipt.status, true, "purchase failed !");

        tools.printfLogs(buyTx)

    });

})