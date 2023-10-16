const DBGovernor = artifacts.require("DBGovernor");//DBTimelock
const DBTimelock = artifacts.require("DBTimelock");//DBTimelock
const NFTImpl = artifacts.require("NFT721Impl");
const USDT = artifacts.require("Usdt");


module.exports = async function (deployer, network, accounts) {
    const _DBGovernor = process.env.DBGovernor
    if (_DBGovernor) {
        await deployer.deploy(NFTImpl, 'DB1', 'DB1')
        const nft = await NFTImpl.deployed();
        console.log('nft Deployed', nft.address);
        //uint256 minDelay, address[] memory proposers, address[] memory executors, address admin
        await deployer.deploy(DBTimelock,
            3600,
            [accounts[1], accounts[2]],
            [accounts[3], accounts[4]],
            accounts[5],
        )
        const dbTimelock = await DBTimelock.deployed();
        console.log(`dbTimelock Deployed ${dbTimelock.address}`);

        await deployer.deploy(DBGovernor,
           nft.address,dbTimelock.address
        )
        
        const dbGovernor = await DBGovernor.deployed()
        console.log(`dbGovernor address : ${dbGovernor.address}`)
    }
}