const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
const args = require('args-parser')

module.exports = async function (callback) {

    const arg = args(process.argv)
    console.log(arg)

    //0xa9059cbb
    // const id = ethers.id('transfer(address,uint256)')
    // console.log(id.substring(0, 10))
    // expect(id.substring(0, 10)).to.equal('0xa9059cbb')

    const usdt = await USDTTest.deployed();
    const aaa = await w(usdt, '100')
    console.log(aaa.toString())

}


async function w(contract, value) {
    const decimals = await contract.decimals()
    return web3.utils.toBN(10).
        pow(
            web3.utils.toBN(decimals)
        ).mul(
            web3.utils.toBN(value)
        );
}

