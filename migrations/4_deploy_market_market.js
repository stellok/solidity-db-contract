const NFTMarket = artifacts.require("NFTMarket");
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const USDT = artifacts.require("Usdt");


module.exports = async function (deployer, network, accounts) {
    if (process.env.nftSwap) {
        var usdt = process.env.usdt
        if (usdt === undefined) {
            const usdtContract = await USDT.deployed();
            usdt = usdtContract.address
            console.log(`usdt address ${usdt}`)
        }
        console.log(`usdt == ${usdt} ${usdt === ''}`)
        await deployer.deploy(NFTMarket, usdt)
        const nftMarket = await NFTMarket.deployed();
        console.log(`nftSwap address : ${nftMarket.address}`)
    }
}