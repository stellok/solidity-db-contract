const USDT = artifacts.require("Usdt");
const BN = require('bn.js');//Dividends
module.exports = async function (deployer, network, accounts) {

    const init = new BN(10).pow(new BN(6)).mul(new BN('10000000000'))
    await deployer.deploy(USDT, init)
    const usdtContract = await USDT.deployed();
    console.log(`USDT contract : ${usdtContract.address}`)

}