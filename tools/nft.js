const NFTImpl = artifacts.require("NFT721Impl");
const axios = require('axios');
require('dotenv').config();

const { NFT_SERVER } = process.env;

module.exports = {
    balanceOf: async function (contractAddr, address) {
        const erc721 = await NFTImpl.at(contractAddr)
        const name = await erc721.name()
        const symbol = await erc721.symbol()
        console.log(`NFT balanceOf ${contractAddr} name ${name} symbol ${symbol}`)
        return erc721.balanceOf(address)
    },

    ownerOf: async function (contractAddr, tokenId) {
        const erc721 = await NFTImpl.at(contractAddr)
        const name = await erc721.name()
        const symbol = await erc721.symbol()
        console.log(`NFT ownerOf ${contractAddr} name ${name} symbol ${symbol}`)
        return erc721.ownerOf(tokenId)
    },


    nftBalance: async function (contractAddr, address) {
        let config = {
            method: 'get',
            maxBodyLength: Infinity,
            url: `${NFT_SERVER}/nft/list`,
            headers: {
                'Content-Type': 'application/json'
            },
            data: JSON.stringify({
                "contract": contractAddr,
                "address": address
            })
        };

        const resp = await axios.request(config)
        const data = resp.data.data
        console.log(data)
        if (data != null) {
            var ids = new Array()
            data.tokenIds.forEach(element => {
                ids.push(parseInt(element))
            });
            return ids
        }
    }
}