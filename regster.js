const args = require('args-parser')
const axios = require('axios');
require('dotenv').config();
const { NFT_SERVER } = process.env;

//truffle exec regster.js --m=PointsSystem --at=0xe90A41918fC30002D1F17D6F4afE3671A94507Cc
module.exports = async function (callback) {

    const arg = args(process.argv)
    console.log(arg)

    if (!arg.m || !arg.at) {
        console.error("Missing arguments: -m [module] -at [address]");
        return;
    }

    const m = artifacts.require(arg.m)

    const rsp = await axios.post(`${NFT_SERVER}/cache/abi`, { contract: arg.at, abi: JSON.stringify(m.abi) })
    console.log(rsp.data)

}