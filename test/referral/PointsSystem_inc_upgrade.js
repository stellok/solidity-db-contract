const { isCallException } = require("ethers");
const nft = require("../../tools/nft");
const { nftBalance } = require("../../tools/nft");
const web3Utils = require("../../tools/web3-utils");
const PointsSystem = artifacts.require("PointsSystem");
const DBM = artifacts.require("DBM");
const USDTTest = artifacts.require("Usdt");
const UserNFT = artifacts.require("UserNft");
const BN = require('bn.js');
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

    const [user1, user2, platform, admin, fee] = accounts

    before(async function () {

        //depoly usdt
        const init = new BN(10).pow(new BN(6)).mul(new BN('10000000000'))
        usdt = await USDTTest.new(init)

        //depoly dbm
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
            await web3Utils.USDTToWei(usdt, '600'),
            fee
        );

        //Sign up for service notifications
        console.log(`server url ${NFT_SERVER}`)
        await axios.post(`${NFT_SERVER}/cache/abi`, { contract: dbm.address, abi: JSON.stringify(dbm.abi) })
        await axios.post(`${NFT_SERVER}/cache/abi`, { contract: userNFT.address, abi: JSON.stringify(userNFT.abi) })
        await axios.post(`${NFT_SERVER}/cache/abi`, { contract: pointsSystem.address, abi: JSON.stringify(pointsSystem.abi) })

        await pointsSystem.setLevel1Price(await web3Utils.USDTToWei(usdt, '100'), { from: admin })

        await userNFT.grantRole(await userNFT.REFERRAL_ROLE(), pointsSystem.address)

        // await web3Utils.transferUSDT(usdt, accounts[0], user1, '100000')
    })

    const mintNft = async (user) => {
        // Check the balance of USDT before the minting
        const balanceBefore = await usdt.balanceOf(user);
        // Mint NFT for the user
        const tx = await pointsSystem.mintNft({ from: user });
        // console.log(tx)
    }

    it("should mint NFT", async () => {
        try {
            await mintNft(user1)
        } catch (error) {
            web3Utils.errors(error, 'insufficient allowance')
        }
        try {
            //no points updsate
            await pointsSystem.upgrade()
        } catch (error) {
            web3Utils.errors(error, 'No staked NFTs')
        }
    });

    it("should increase", async () => {

        await pointsSystem.increase(0, 2, user1, 1200, { from: platform })
        expect((await pointsSystem.Score(user1)).toString()).to.equal('1200')

        await mintNft(user1)
        expect((await pointsSystem.Score(user1)).toString()).to.equal('200')

        //try upgrade level --> 1 expect staked
        try {
            await pointsSystem.upgrade()
        } catch (error) {
            web3Utils.errors(error, "No staked NFTs")
        }

        //try mint again , expect 'You've mint NFT'
        try {
            await mintNft(user1)
        } catch (error) {
            web3Utils.errors(error, "You've mint NFT")
        }

        //check nft number
        await web3Utils.timeout(6000)
        const hold = await nft.nftBalance(userNFT.address, user1)
        const [tokenId] = hold
        expect(tokenId).to.equal(1)
    })


    const stakeNft = async (user, tokenid) => {
        //nft balance
        const hold = await nft.nftBalance(userNFT.address, user)
        const [tokenId] = hold
        expect(tokenId).to.equal(tokenid)

        //nft approve
        await userNFT.approve(pointsSystem.address, tokenId, { from: user });
        // stake nft
        await pointsSystem.stake(tokenId, { from: user })
        const balance = await nft.balanceOf(userNFT.address, pointsSystem.address)
        expect(balance.toNumber()).to.equal(tokenId)

        //check stake
        const id = await pointsSystem.checkStaked(user)
        expect(id.toNumber()).to.equal(tokenId)
    }

    it("should stake nft", async () => {
        const user1Score = await pointsSystem.Score(user1)
        console.log(`user1 score ${user1Score}`)

        //stake nft ,first time
        await stakeNft(user1, 1)
        const currentLevel = await pointsSystem.currentLevel(user1)
        console.log(`user1 currentLevel ${currentLevel}`)
        expect(currentLevel.toString()).to.equal('1')

        try {
            await pointsSystem.upgrade()
        } catch (error) {
            web3Utils.errors(error, "Not enough point")
        }
    })

    it("should upgrade", async () => {
        await pointsSystem.increase(0, 2, user1, 2000, { from: platform })

        //show before 
        const before = await pointsSystem.pendingReward(user1, 0)
        console.log(`pending before ${before.toString()}`)
        //upgrade level 1 ==> 2
        await pointsSystem.upgrade()

        const newLocal = await pointsSystem.pendingReward(user1, 0)
        console.log(`pending ${newLocal.toString()}`)
        // expect(newLocal.toString()).to.equal('10000000000000000000')
        const currentLevel = await pointsSystem.currentLevel(user1)
        expect(currentLevel.toString()).to.equal('2')
    })

    it("should rewardsReferral", async () => {

        const dbmToken = await web3Utils.USDTToWei(dbm, 500)
        await pointsSystem.rewardsReferral(0, 1, user1, dbmToken, { from: platform })
        const newLocal = await pointsSystem.pendingReward(user1, 1)
        console.log(`rewardsReferral ${newLocal.toString()}`)
        // expect(newLocal).to.equal(dbmToken.toString())

        try {
            await pointsSystem.withdrawReward(1, { from: user1 })
        } catch (error) {
            web3Utils.errors(error, "dbm token has not started yet")
        }
    })


    it("should unStake", async () => {

        await pointsSystem.unStake({ from: user1 })
        await web3Utils.timeout(6000)
        const [tokenId] = await nft.nftBalance(userNFT.address, user1)
        expect(tokenId).to.equal(1)

    })


    it("should increase-upgrade", async () => {

        await pointsSystem.increase(0, 2, user1, 2300, { from: platform })
        try {
            await pointsSystem.upgrade({ from: user1 })
        } catch (error) {
            web3Utils.errors(error, "No staked NFTs")
        }

    })

    it("should nft user1 ==> user2", async () => {
        const [tokenId1] = await nft.nftBalance(userNFT.address, user1)
        await userNFT.safeTransferFrom(user1, user2, tokenId1, { from: user1 })
        //expect No staked NFTs
        try {
            const level = await pointsSystem.currentLevel(user2)
            console.log(`${user2} level ${level}`)
        } catch (error) {
            web3Utils.errors(error, 'No staked NFTs')
        }
        await web3Utils.timeout(6000)
        await stakeNft(user2, tokenId1)
        const level = await pointsSystem.currentLevel(user2)
        console.log(`${user2} level ${level}`)

        //expect: You already have level
        try {
            await mintNft(user2)
        } catch (error) {
            web3Utils.errors(error, "You already have level")
        }

    })





});