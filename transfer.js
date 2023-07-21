const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
const args = require('args-parser')

module.exports = async function (callback) {

    const arg = args(process.argv)
    console.log(arg)

    //truffle exec transfer.js --contract=0xdAC17F958D2ee523a2206206994597C13D831ec7 --to=0xdAC17F958D2ee523a2206206994597C13D831ec7 --value=100
    const usdt = await USDTTest.deployed();
    
    // const result = await usdt.transfer(arg.to, web3.utils.toWei(arg.value, 'ether'))
    // console.log(`status ${result.receipt.status}`)

    // console.log(usdt.abi)

    console.log(usdt.transfer)

    for (let index = 0; index < usdt.abi.length; index++) {
       const abi = usdt.abi[index]
       console.log(`name ${abi.name} signature ${abi.signature}`)
    }

    // callback();
}

