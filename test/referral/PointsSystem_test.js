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

contract("PointsSystem", (accounts) => {
    let pointsSystem;
    let dbm;
    let userNFT;
    let usdt;
    let args;

    const user1 = accounts[1];
    const user2 = accounts[2];

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
            accounts[0],
            accounts[0],
        );

        //Sign up for service notifications
        await axios.post(`${NFT_SERVER}/cache/abi`, { contract: dbm.address, abi: JSON.stringify(dbm.abi) })
        await axios.post(`${NFT_SERVER}/cache/abi`, { contract: userNFT.address, abi: JSON.stringify(userNFT.abi) })
        await axios.post(`${NFT_SERVER}/cache/abi`, { contract: pointsSystem.address, abi: JSON.stringify(pointsSystem.abi) })

        await pointsSystem.setLevel1Price(await web3Utils.USDTToWei(usdt, '100'))

        await userNFT.grantRole(await userNFT.REFERRAL_ROLE(), pointsSystem.address)

        await web3Utils.transferUSDT(usdt, accounts[0], user1, '100000')
    })

    it("should mint NFT", async () => {
        // Get the first NFT price
        const amount = await pointsSystem.firstNftPrice();

        // Approve the transfer of USDT tokens to the PointsSystem contract
        await usdt.approve(pointsSystem.address, amount, { from: user1 });

        // Check the balance of USDT before the minting
        const balanceBefore = await usdt.balanceOf(user1);
        // Mint NFT for the user
        const tx = await pointsSystem.mintNft({ from: user1 });
        // console.log(tx)

        // Check if the user's NFT balance is 1
        const balance = await userNFT.balanceOf(user1);
        assert.equal(balance, 1, "User does not have 1 NFT");

        // Check if the user's level is 1
        const level = await pointsSystem.currentLevel(user1);
        assert.equal(level, 1, "User level is not 1");

        const balanceAfter = await usdt.balanceOf(user1);
        assert.equal(balanceAfter.sub(balanceBefore), -amount, "Incorrect USDT balance");
    });

    it("should stake NFT", async () => {
        const hold = await nft.nftBalance(userNFT.address, user1)
        console.log(hold)
        // Approve the transfer of NFT to the PointsSystem contract
        await userNFT.approve(pointsSystem.address, 1, { from: user1 });
        //function stake(uint256 _tokenId) public
        // Stake the NFT
        await pointsSystem.stake(1, { from: user1 });
        //Check if the user's staked NFT is correct
        const stakedNFT = await pointsSystem.checkStaked(user1);
        assert.equal(stakedNFT, 1, "Incorrect staked NFT");

        // Check if the user still has the NFT
        const balance = await userNFT.balanceOf(user1);
        assert.equal(balance, 0, "User still has the NFT");
    })

});