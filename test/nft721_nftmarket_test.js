const Web3 = require('web3');
const NFTMarket = artifacts.require("NFTMarket");
const NFTImpl = artifacts.require("NFT721Impl");
const USDTTest = artifacts.require("Usdt");
const BN = require('bn.js');
const ethers = require("ethers");
const tools = require('../tools/web3-utils');

contract("nft721_nftswap_test", (accounts) => {

    let user = accounts[5]
    let nft;
    let swap;

    before(async function () {
        // const bid = await BiddingTest.deployed();
        //depoly usdt
        const init = new BN(10).pow(new BN(6)).mul(new BN('10000000000'))
        usdt = await USDTTest.new(init)

        // //transfer usdt
        // console.log(`\n using account ${user} as user ! `)
        await tools.printUSDT(usdt, accounts[0])

        await tools.transferUSDT(usdt, accounts[0], user, '100000')

        nft = await NFTImpl.new("db", "db")
        console.log(`nft ${nft.address}`)


        swap = await NFTMarket.new(usdt.address)
        console.log(`swap ${swap.address}`)

        const tx = await nft.mint(accounts[2], 10);
        assert.equal(tx.receipt.status, true, "mint failed !");

    });


    it("testing list() should assert true", async function () {

        const tx = await nft.approve(swap.address, 1, { from: accounts[2] })
        assert.equal(tx.receipt.status, true, "approve failed !");
        const listTx = await swap.list(nft.address, 1, await tools.USDTToWei(usdt, 1), { from: accounts[2] })
        assert.equal(listTx.receipt.status, true, "list failed !");

    });

    const purchase = async function () {

        const order = await swap.inOrder(nft.address, 1)
        console.log(`order tokenID 1 ${order}`)
        //
        const ap = await usdt.approve(swap.address, order.price, { from: user })
        assert.equal(ap.receipt.status, true, "approve failed !");

        const buyTx = await swap.purchase(nft.address, 1, { from: user })
        assert.equal(buyTx.receipt.status, true, "purchase failed !");
    }

    const batchPurchase = async function () {

        const order = await swap.inOrder(nft.address, 1)
        console.log(`order tokenID 1 ${order}`)
        //
        const ap = await usdt.approve(swap.address, order.price, { from: user })
        assert.equal(ap.receipt.status, true, "approve failed !");

        const buyTx = await swap.batchPurchase(nft.address, [1, 2, 3], { from: user })
        assert.equal(buyTx.receipt.status, true, "purchase failed !");

    }

    it("testing purchase() should assert true", purchase);

    it("testing purchase1() should assert true", async function () {
        try {
            await purchase()
        } catch (error) {
            tools.errors(error, 'Invalid Order')
        }
    });

    it("testing batchPurchase() should assert true", batchPurchase);

})