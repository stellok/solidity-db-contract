const NFTImpl = artifacts.require("NFT721Impl");
module.exports = {
    balanceOf: async function (contract,address) {
        const erc721 = await NFTImpl.at(contract)
        const name = await erc721.name()
        const symbol = await erc721.symbol()
        console.log(`NFT contract ${contract} name ${name} symbol ${symbol}`)
        return erc721.balanceOf(address)
     },

     ownerOf: async function (contract,tokenId) {
        const erc721 = await NFTImpl.at(contract)
        const name = await erc721.name()
        const symbol = await erc721.symbol()
        console.log(`NFT contract ${contract} name ${name} symbol ${symbol}`)
        return erc721.ownerOf(tokenId)
     }
}