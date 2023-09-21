const nftSwap = artifacts.require("NFTMarket");
const NFTImpl = artifacts.require("NFT721Impl");
const USDT = artifacts.require("Usdt");


module.exports = async function (deployer, network, accounts) {
    const nftSwapEnv = process.env.nftSwap
    if (nftSwapEnv) {
        const usdtContract = await USDT.deployed();
        await deployer.deploy(NFTImpl, 'DB1', 'DB1')
        await deployer.deploy(nftSwap, usdtContract.address)
        const sp = await nftSwap.deployed()
        console.log(`nftSwap address : ${sp.address}`)
    }
}