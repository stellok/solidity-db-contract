const PointsSystem = artifacts.require("PointsSystem");
const UserNft = artifacts.require("UserNft");

contract("PointsSystem", (accounts) => {
    let pointsSystem;
    let userNft;
    let referral;
    let mockToken;

    const PlatformRole = web3.utils.keccak256("PLATFORM");
    const minterRole = web3.utils.keccak256("MINTER_ROLE");

    before(async () => {

        userNft = await UserNft.new("UserNFT", "NFT");
        pointsSystem = await PointsSystem.new(mockToken.address, userNft.address, referral.address, accounts[1]);

        // Assign the MINTER_ROLE to the PointsSystem contract
        await userNft.grantRole(minterRole, pointsSystem.address);
    });

    describe("increase", () => {
        it("should increase the points of a user", async () => {
            const user = accounts[2];
            const score = 100;

            await pointsSystem.increase(0, user, score);

            const userScore = await pointsSystem.Score(user);
            assert.equal(userScore, score);
        });
    });

    describe("mintNft", () => {
        it("should mint an NFT for the user", async () => {
            const user = accounts[2];
            const firstNftPrice = await pointsSystem.firstNftPrice();

            await mockToken.approve(pointsSystem.address, firstNftPrice, { from: user });
            await pointsSystem.mintNft({ from: user });

            const userLevel = await pointsSystem.currentLevel(user);
            assert.equal(userLevel, 1);

            const stakeNFT = await pointsSystem.checkStaked(user);
            assert.notEqual(stakeNFT.toNumber(), 0);
        });
    });

    describe("stake", () => {
        it("should stake an NFT", async () => {
            const user = accounts[2];
            const tokenId = 1;

            await userNft.safeMint(user, `tokenURI_${tokenId}`);
            await userNft.approve(pointsSystem.address, tokenId, { from: user });
            await pointsSystem.stake(tokenId, { from: user });

            const stakeNFT = await pointsSystem.checkStaked(user);
            assert.equal(stakeNFT, tokenId);
        });
    });

    describe("upgrade", () => {
        it("should upgrade the user's level", async () => {
            const user = accounts[2];

            await mockToken.approve(pointsSystem.address, 100, { from: user });
            await pointsSystem.upgrade({ from: user });

            const userLevel = await pointsSystem.currentLevel(user);
            assert.equal(userLevel, 2);
        });
    });

    describe("unStake", () => {
        it("should unstake an NFT", async () => {
            const user = accounts[2];
            const tokenId = await pointsSystem.checkStaked(user);

            await pointsSystem.unStake({ from: user });

            const stakeNFT = await pointsSystem.checkStaked(user);
            assert.equal(stakeNFT, 0);

            const owner = await userNft.ownerOf(tokenId);
            assert.equal(owner, user);
        });
    });

    describe("rewardsReferral", () => {
        it("should update the pending reward of a user", async () => {
            const user = accounts[2];

            await pointsSystem.rewardsReferral(0, user, 100);

            const pendingReward = await pointsSystem.users(user);
            assert.equal(pendingReward.pendingReward, 100);
        });
    });

    describe("withdrawReward", () => {
        it("should withdraw the pending reward of a user", async () => {
            const user = accounts[2];
            const pendingReward = await pointsSystem.users(user).pendingReward;

            await pointsSystem.withdrawReward({ from: user });

            const updatedPendingReward = await pointsSystem.users(user).pendingReward;
            assert.equal(updatedPendingReward, 0);

            const userBalance = await mockToken.balanceOf(user);
            assert.equal(userBalance, pendingReward);
        });
    });
});