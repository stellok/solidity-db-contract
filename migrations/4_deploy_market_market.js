const NFTMarket = artifacts.require("NFTMarket");
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const USDT = artifacts.require("Usdt");


module.exports = async function (deployer, network, accounts) {
    var usdt = process.env.usdt
    if (process.env.nftMarket) {
        if (usdt === undefined) {
            console.log("usdtAdd not set")
            return
        }
        console.log(`usdt == ${usdt} ${usdt === ''}`)
        await deployer.deploy(NFTMarket, usdt)
        const nftMarket = await NFTMarket.deployed();
        console.log(`NFTMarket address : ${nftMarket.address}`)
    }
}