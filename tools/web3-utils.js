const BN = require('bn.js');
const USDTTest = artifacts.require("Usdt");

module.exports = {
    printfLogs: function (params) {
        console.log(`logs: ${JSON.stringify(params.receipt, null, 3)}`)
    },
    timeout: function (ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    },
    getsignature: function (contract, name) {
        for (let index = 0; index < contract.abi.length; index++) {
            const abi = contract.abi[index]
            if (name === abi.name) {
                //substring(2, 10)
                return abi.signature.substring(2, 10)
            }
            // console.log(`name ${abi.name} signature ${abi.signature}`)
        }
    },
    USDTToWei: async function (contract, value) {
        const decimals = await contract.decimals()
        return new BN(10).
            pow(
                new BN(decimals)
            ).mul(
                new BN(value)
            )
    },

    toBN: function (valuue) {
        return new BN(valuue)
    },

    USDTFromWei: async function (contract, value) {
        const decimals = await contract.decimals()
        return this.toBN(value).div(new BN(10).
        pow(
            new BN(decimals)
        ))
    },

    AssertUSDT: async function (contract, address, expectBalance) {
        const usdt = await USDTTest.at(contract)
        const usdtBalance = await usdt.balanceOf(address);
        assert.equal(usdtBalance, expectBalance.toString(), `${usdtBalance} != expectBalance ${expectBalance}`);
    }

}


