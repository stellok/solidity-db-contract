const Bidding = artifacts.require("Bidding");
const USDT = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");

module.exports = async function(deployer,network,accounts) {

    //deployment usdt
    await deployer.deploy(USDT, 100000000000);
    //access information about your deployed contract instance
    const usdtContract = await USDT.deployed();
    console.log(`USDT contract ${usdtContract.address}`)
    const usdtBalance = await usdtContract.balanceOf(accounts[0]);
    console.log(`owner ${accounts[0]}`)
    console.log(`Owner USDT Balance: ${usdtBalance}`)

    //deploy bidding
    await deployer.deploy(Bidding,
        usdtContract.address, // IERC20 usdtAddr_
        accounts[0],          // address owner_,
        accounts[0],          // address founderAddr_
        accounts[0],          // address adminAddr_
        1,                    // service fee
        7,                    // dd fee
        accounts[0])          // address ddAddr_
    const bidContract = await Bidding.deployed()
    console.log(`bidding contract ${bidContract.address}`)



};