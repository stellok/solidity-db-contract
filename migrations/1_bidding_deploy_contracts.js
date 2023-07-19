const Bidding = artifacts.require("Bidding");
const USDT = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");

const Web3 = require('web3');

module.exports = async function (deployer, network, accounts) {

    //deployment usdt
    await deployer.deploy(USDT, web3.utils.toWei('10000000000', 'ether'));
    //access information about your deployed contract instance
    const usdtContract = await USDT.deployed();
    console.log(`USDT contract : ${usdtContract.address}`)
    const usdtBalance = await usdtContract.balanceOf(accounts[0]);
    console.log(`owner : ${accounts[0]}`)
    console.log(`Owner USDT Balance: ${web3.utils.fromWei(usdtBalance, 'ether')}`)

    //deploy bidding
    await deployer.deploy(Bidding,
        usdtContract.address,                     // IERC20 usdtAddr_
        accounts[0],                              // address founderAddr_
        accounts[0],                              // address adminAddr_
        web3.utils.toWei('10000', 'ether'),       // service fee
        web3.utils.toWei('90000', 'ether'),       // dd fee
        accounts[0],                              // address ddAddr_
        accounts[1]                               // platformFeeAddr_
    )

    const bidContract = await Bidding.deployed()
    console.log(`bidding contract : ${bidContract.address}`)



};