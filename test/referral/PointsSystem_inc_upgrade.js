const { isCallException } = require("ethers");
const nft = require("../../tools/nft");
const { nftBalance } = require("../../tools/nft");
const web3Utils = require("../../tools/web3-utils");
const PointsSystem = artifacts.require("PointsSystem");
const DBM = artifacts.require("DBM");
const USDTTest = artifacts.require("Usdt");
const UserNFT = artifacts.require("UserNft");
const Args = artifacts.require("Args");
const axios = require('axios');
require('dotenv').config();
const { NFT_SERVER } = process.env;

contract("PointsSystem_inc_upgrade", (accounts) => {
    let pointsSystem;
    let dbm;
    let userNFT;
    let usdt;
    let args;

    const [user1, user2, platform, admin] = accounts

    before(async function () {

        usdt = await USDTTest.deployed();
        dbm = await DBM.new(await web3Utils.USDTToWei(usdt, '10000'), accounts[0]);

        userNFT = await UserNFT.new("UserNFT", "UNFT");
        console.log(`user NFT ${userNFT.address}`)

        args = await Args.new()

        // IERC20 dbm_,
        // IERC20 usdt_,
        // IPointsArgs args_,
        // IReferral nft_,
        // address platFormAddr_,
        // address admin_
        pointsSystem = await PointsSystem.new(
            usdt.address,
            args.address,
            userNFT.address,
            platform,
            admin,
        );

        //Sign up for service notifications
        await axios.post(`${NFT_SERVER}/cache/abi`, { contract: dbm.address, abi: JSON.stringify(dbm.abi) })
        await axios.post(`${NFT_SERVER}/cache/abi`, { contract: userNFT.address, abi: JSON.stringify(userNFT.abi) })
        await axios.post(`${NFT_SERVER}/cache/abi`, { contract: pointsSystem.address, abi: JSON.stringify(pointsSystem.abi) })

        await pointsSystem.setLevel1Price(await web3Utils.USDTToWei(usdt, '100'), { from: admin })

        await userNFT.grantRole(await userNFT.REFERRAL_ROLE(), pointsSystem.address)

        // await web3Utils.transferUSDT(usdt, accounts[0], user1, '100000')
    })

    const mintNft = async () => {
        // Check the balance of USDT before the minting
        const balanceBefore = await usdt.balanceOf(user1);
        // Mint NFT for the user
        const tx = await pointsSystem.mintNft({ from: user1 });
        // console.log(tx)
    }

    it("should mint NFT", async () => {
        try {
            await mintNft()
        } catch (error) {
            assert(error.message.includes("insufficient allowance"), "Expected an error with message 'Error message'.");
        }
        try {
            await pointsSystem.upgrade()
        } catch (error) {
            assert(error.message.includes("Not enough points"), "Expected an error with message 'Error message'.");
        }
    });

    it("should increase", async () => {
        await pointsSystem.increase(2, user1, 1200, { from: platform })
        try {
            await mintNft()
        } catch (error) {
            assert(error.message.includes("Please upgrade first"), "Expected an error with message 'Error message'.");
        }
        expect((await pointsSystem.Score(user1)).toString()).to.equal('1200')
        await pointsSystem.upgrade()
        expect((await pointsSystem.currentLevel(user1)).toString()).to.equal('1')
        await mintNft()
        const hold = await nft.nftBalance(userNFT.address, user1)
        console.log(hold)

    })

});