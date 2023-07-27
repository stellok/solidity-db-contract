const NFTImpl = artifacts.require("NFT721Impl");
module.exports = {
    balanceOf: async function (contractAddr,address) {
        const erc721 = await NFTImpl.at(contractAddr)
        const name = await erc721.name()
        const symbol = await erc721.symbol()
        console.log(`NFT contract ${contractAddr} name ${name} symbol ${symbol}`)
        return erc721.balanceOf(address)
     },

     ownerOf: async function (contractAddr,tokenId) {
        const erc721 = await NFTImpl.at(contractAddr)
        const name = await erc721.name()
        const symbol = await erc721.symbol()
        console.log(`NFT contract ${contractAddr} name ${name} symbol ${symbol}`)
        return erc721.ownerOf(tokenId)
     }
}