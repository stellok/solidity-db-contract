const BN = require('bn.js');
const { balanceOf } = require('./nft');
const USDTTest = artifacts.require("Usdt");

module.exports = {
    printfLogs: function (params, bool) {
        console.log(`logs: ${JSON.stringify(params.receipt.logs, null, 3)}`)
    },
    timeout: function (ms) {
        console.log(`wait for ${ms}`)
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

    AssertUSDT: async function (contractAddr, address, expectBalance) {
        const usdt = await USDTTest.at(contractAddr)
        const usdtBalance = await usdt.balanceOf(address);
        if (!this.toBN(expectBalance).eq(usdtBalance)) {
            assert.fail(`${usdtBalance.toString()} != expectBalance ${expectBalance.toString()}`)
        }
    },

    balanceOF: async function (contractAddr, address) {
        const usdt = await USDTTest.at(contractAddr)
        const usdtBalance = await usdt.balanceOf(address);
        return usdtBalance
    },
    transferUSDT: async function (contract, from, to, value) {
        const ba = await this.printUSDT(contract, to)
        const amount = await this.USDTToWei(contract, value)
        const result = await contract.transfer(to, amount, { from: from })
        assert.equal(result.receipt.status, true, "transfer usdt failed !");
        console.log(`transfer ${from} ==> ${to} ${value} USDT \n`)
        await this.AssertUSDT(contract.address, to, amount.add(ba))
    },
    printUSDT: async function (contract, account) {
        const balance = await this.balanceOF(contract.address, account)
        const b = await this.USDTFromWei(contract, balance)
        console.log(`balance ${account} ${b} USDT`)
        return balance
    },
    approve: async function (contract, to, amount, caller) {
        let resultApprove = await contract.approve(to, amount, { from: caller })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");
    },
    errors: async function(error,include){
        assert(error.message.includes(include), `Expected an error with message ${error}`);
    }

}


