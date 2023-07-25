const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
var tools = require('../tools/web3-utils');

contract("BiddingTest-MinerIntentMoney", (accounts) => {


    let miner = accounts[3]

    before(async function () {
        const usdt = await USDTTest.deployed();
        console.log(`\n using account ${miner} as miner ! `)
        const amount = await tools.USDTToWei(usdt, '100000')
        const result = await usdt.transfer(miner, amount)
        assert.equal(result.receipt.status, true, "transfer usdt failed !");
        const balance = await usdt.balanceOf(miner)
        const minerAmount = await tools.USDTFromWei(usdt,balance)
        console.log(` ${miner} ${balance} ${minerAmount} USDT \n`)
    });

    const stakeAmount = web3.utils.toWei('10000', 'ether')

    it("testing minerIntentMoney() should assert true", async function () {

        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        let resultApprove = await usdt.approve(bid.address, stakeAmount, { from: miner })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        let expire = 1690429294
        //sign message
        let digest = ethers.solidityPackedKeccak256(["address", "string", "address", "uint256", "uint256"], [bid.address, tools.getsignature(bid, 'minerIntentMoney'), miner, stakeAmount, expire])
        console.log(`digest : ${digest}`)

        console.log(`owner : ${accounts[0]}`)
        let signature = await web3.eth.sign(digest, accounts[0])
        // console.log(`signed: ${msg}`)

        signature = signature.substr(0, 130) + (signature.substr(130) == "00" ? "1b" : "1c");

        //recover
        const recover = web3.eth.accounts.recover(digest, signature)
        expect(recover).to.equal(accounts[0])
        console.log(`recover : ${recover}`)


        //call  minerIntentMoney
        let result = await bid.minerIntentMoney(stakeAmount, expire, signature, { from: miner });
        assert.equal(result.receipt.status, true, "minerIntentMoney failed !");
        console.log(`logs : ${JSON.stringify(result.receipt.logs, null, 3)} \n`)

        // let balanceOf =  await usdt.balanceOf(bid.address);
        // console.log(`balanceOf ${balanceOf}`)
        // assert.equal(balanceOf, serviceFee, "payServiceFee function testing failed !");

    });

    it("testing unMinerIntentMoney() should assert true", async function () {

        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();
        //_msgSender(), signType.unMinerStake, expire

        let origUsdtBalance = await usdt.balanceOf(miner);
        console.log(`origUsdtBalance : ${web3.utils.fromWei(origUsdtBalance, 'ether')}`)

        let expire = 1690429294
        const nonce = 0
        const intentMoneyAmount = await bid.IntentMoneyAmount(miner)
        console.log(`intentMoneyAmount = ${intentMoneyAmount}`)

        //sign message
        let digest = ethers.solidityPackedKeccak256(["address", "string", "address", "uint256", "uint256", "uint256"], [bid.address, tools.getsignature(bid, 'unMinerIntentMoney'), miner, expire, intentMoneyAmount.toString(), nonce])
        console.log(`digest : ${digest}`)

        console.log(`owner ${accounts[0]}`)
        let signature = await web3.eth.sign(digest, accounts[0])
        // console.log(`signed: ${msg}`)

        signature = signature.substr(0, 130) + (signature.substr(130) == "00" ? "1b" : "1c");

        //recover
        const recover = web3.eth.accounts.recover(digest, signature)
        expect(recover).to.equal(accounts[0])
        console.log(`recover : ${recover}`)

        //call unMinerIntentMoney
        let result = await bid.unMinerIntentMoney(expire, intentMoneyAmount, nonce, signature, { from: miner });
        assert.equal(result.receipt.status, true, "minerIntentMoney failed !");
        console.log(`result ${JSON.stringify(result.receipt.logs)}`)

        let balanceOf = await usdt.balanceOf(miner);
        console.log(`Now balance : ${web3.utils.fromWei(balanceOf, 'ether')}`)
        expect(web3.utils.fromWei(balanceOf, 'ether')).to.equal('90000')
    });

})