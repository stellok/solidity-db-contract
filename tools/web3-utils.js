
module.exports = {
    printfLogs: function (params) {
        console.log(`logs: ${JSON.stringify(params.receipt.logs, null, 3)}`)
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
    }
}


