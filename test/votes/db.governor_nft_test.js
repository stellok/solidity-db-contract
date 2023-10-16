const Web3 = require('web3');
const NFTMarket = artifacts.require("NFTMarket");
const DBGovernor = artifacts.require("DBGovernor");//DBTimelock
const NFTImpl = artifacts.require("NFT721Impl");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
const tools = require('../../tools/web3-utils');

contract("db.governor_nft_test", (accounts) => {

    let user = accounts[5]

    it("testing mint() should assert true", async function () {

        const nft = await NFTImpl.deployed();
        const tx = await nft.mint(accounts[2], 10);
        assert.equal(tx.receipt.status, true, "mint failed !");

    });

    const delegate = async function (from, to) {
        const nft = await NFTImpl.deployed();
        const tx = await nft.delegate(to, { from: from })
        assert.equal(tx.receipt.status, true, "delegate failed !");
    }

    it("testing transfer() should assert true", async function () {
        //function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        const nft = await NFTImpl.deployed();
        const tx = await nft.safeTransferFrom(accounts[2], accounts[3], 1, { from: accounts[2] })
        assert.equal(tx.receipt.status, true, "mint failed !")

        const bnTimepoint = await web3.eth.getBlockNumber()
        console.log(`blockNumber ${bnTimepoint}`)

        await tools.timeout(5000)

        await delegate(accounts[3], accounts[3])

        await tools.timeout(5000)

        const votesblockNumber = await nft.getPastVotes(accounts[3], bnTimepoint)
        console.log(`getPastVotes ${votesblockNumber}`)
        // const vf = nft.getPastVotes(accounts[3],timepoint)

        const votes = await nft.getVotes(accounts[3])
        console.log(`user ${accounts[3]} votes ${votes}`)

    })

})