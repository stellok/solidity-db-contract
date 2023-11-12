const PointsSystem = artifacts.require("PointsSystem");
const DBM = artifacts.require("DBM");
const USDT = artifacts.require("Usdt");
const Args = artifacts.require("Args")
const UserNft = artifacts.require("UserNft");
const tools = require('../tools/web3-utils');

// referral=true usdt=0x2b12300398f4bbd4c278a6435e712561074ba453 PointsSystem=true truffle deploy
// referral=true userNft=0x75277a5b4295d47a1Df3f9D2D7baD98ACC086F23 usdt=0x2b12300398f4bbd4c278a6435e712561074ba453 dbm=0x4F71b3600adA5763062F7d0C3a85069d3AACEc3A PointsSystemSetings=true truffle deploy --network polygon
module.exports = async function (deployer, network, accounts) {

    if (process.env.referral === undefined) {
        return
    }
    const dep = accounts[1]
    var usdt = process.env.usdt
    var dbm = process.env.dbm
    var userNft = process.env.userNft
    var pointsSystem = process.env.PointsSystem
    var args = process.env.args

    if (usdt === undefined) {
        const usdtContract = await USDT.deployed();
        usdt = usdtContract.address
        console.log(`usdt address ${usdt}`)
    }

    if (userNft === undefined) {
        await deployer.deploy(UserNft, "DB-NFT", "DB-NFT", { from: dep })
        const uNFt = await UserNft.deployed();
        userNft = uNFt.address
        console.log(`userNft address ${userNft}`)
    }

    // if (dbm === undefined) {
    //     const cusdt = await USDT.at(usdt)
    //     await deployer.deploy(DBM, await tools.USDTToWei(cusdt, '10000000'), accounts[0], { from: dep })
    //     const _dbm = await DBM.deployed()
    //     dbm = _dbm.address
    //     console.log(`dbm address ${dbm}`)
    // }

    if (args === undefined) {
        await deployer.deploy(Args)
        const _args = await Args.deployed()
        args = _args.address
        console.log(`args address ${args}`)
    }

    if (pointsSystem === undefined) {
        // IERC20 dbm_,
        // IERC20 usdt_,
        // IPointsArgs args_,
        // IReferral nft_,
        // address platFormAddr_,
        // address admin_
        console.log(`usdt == ${usdt} ${usdt === ''}`)
        await deployer.deploy(PointsSystem,
            usdt,
            args,
            userNft,
            '0x25CFF0Fcfd8F04116249298F43d1F90b946A76C0',
            '0x8d0be07353e6A9902842a28a3DCAcEFBD09C318c',
            { from: dep })
        const ps = await PointsSystem.deployed()
        console.log(`PointsSystem address : ${ps.address}`)
        pointsSystem = ps.address
    }

    if (process.env.PointsSystemSetings) {

        const ps = await PointsSystem.at(pointsSystem)
        const nft = await UserNft.at(userNft)
        await nft.grantRole(await nft.REFERRAL_ROLE(), ps.address, { from: dep })

        // const cusdt = await USDT.at(usdt)
        // await ps.setLevel1Price(await tools.USDTToWei(cusdt, '100'), { from: dep })
    }
}