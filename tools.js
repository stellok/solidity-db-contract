const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
const args = require('args-parser')

module.exports = async function (callback) {

    const arg = args(process.argv)
    console.log(arg)

    //0xa9059cbb
    const id = ethers.id('transfer(address,uint256)')
    console.log(id.substring(0, 10))
    expect(id.substring(0, 10)).to.equal('0xa9059cbb')

    console.log(moment().add(3, 'days'))

}


