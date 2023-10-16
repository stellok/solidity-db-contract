const NFTImpl = artifacts.require("NFT721Impl");
const axios = require('axios');

module.exports = {
    balanceOf: async function (contractAddr,address) {
        const erc721 = await NFTImpl.at(contractAddr)
        const name = await erc721.name()
        const symbol = await erc721.symbol()
        console.log(`NFT balanceOf ${contractAddr} name ${name} symbol ${symbol}`)
        return erc721.balanceOf(address)
     },

     ownerOf: async function (contractAddr,tokenId) {
        const erc721 = await NFTImpl.at(contractAddr)
        const name = await erc721.name()
        const symbol = await erc721.symbol()
        console.log(`NFT ownerOf ${contractAddr} name ${name} symbol ${symbol}`)
        return erc721.ownerOf(tokenId)
     },

     
     nftBalance: async function (contract, address) {
      let config = {
          method: 'get',
          maxBodyLength: Infinity,
          url: 'http://192.168.1.115:8088/nft/list',
          headers: {
              'Content-Type': 'application/json'
          },
          data: JSON.stringify({
              "contract": contract,
              "address": address
          })
      };

      const resp = await axios.request(config)
      const data = resp.data.data
      var ids = new Array()
      data.tokenIds.forEach(element => {
          ids.push(parseInt(element))
      });
      return ids
  }
}