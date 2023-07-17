const Bidding = artifacts.require("Bidding");
const USDT = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");

module.exports = async function(deployer,network,accounts) {

    //deployment usdt
    await deployer.deploy(USDT, 100000000000);
    //access information about your deployed contract instance
    const usdtContract = await USDT.deployed();
    console.log(`USDT contract ${usdtContract.address}`)

    //deploy bidding
    await deployer.deploy(Bidding,usdtContract.address,accounts[0],accounts[1],accounts[2],1,7,accounts[0])
    const bidContract = await Bidding.deployed()
    console.log(`bidding contract ${bidContract.address}`)



};