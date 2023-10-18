const USDT = artifacts.require("Usdt");
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const BN = require('bn.js');//Dividends
const web3Utils = require('../tools/web3-utils');

module.exports = async function (deployer, network, accounts) {

        //process.env.USDTDeploy   
        const init = new BN(10).pow(new BN(6)).mul(new BN('10000000000'))
        // const usdt = await deployProxy(USDT, [init], { deployer })
        // console.log(`USDT contract : ${usdt.address}`)

        await deployer.deploy(USDT,init)
        const usdtContract = await USDT.deployed()
        console.log(`USDT contract : ${usdtContract.address}`)

        // await web3Utils.printUSDT(usdtContract, accounts[0])
    
}