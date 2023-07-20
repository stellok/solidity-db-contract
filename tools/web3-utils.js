
module.exports = {
    printfLogs: function (params) {
        console.log(`logs: ${JSON.stringify(params.receipt.logs, null, 3)}`)
    },
    timeout: function (ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}


