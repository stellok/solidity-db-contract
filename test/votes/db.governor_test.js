const Web3 = require('web3');
const NFTMarket = artifacts.require("NFTMarket");
const DBGovernor = artifacts.require("DBGovernor");//DBTimelock
const NFTImpl = artifacts.require("NFT721Impl");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
const tools = require('../../tools/web3-utils');

contract("db.governor_test", (accounts) => {

    let user = accounts[5]

    before(async function () {

        const nft = await NFTImpl.deployed();
        const tx = await nft.mint(accounts[2], 10);
        assert.equal(tx.receipt.status, true, "mint failed !");
        
    });


    it("testing propose() should assert true", async function () {
        const dbGovernor = await DBGovernor.deployed();
        const nft = await NFTImpl.deployed();

        const token = new ethers.Interface(nft.abi)
        //approve(address to, uint256 tokenId)
        const inputData = token.encodeFunctionData('approve', ['0x8d0be07353e6a9902842a28a3dcacefbd09c318c', 12]);
        console.log(`input data ${inputData}`)

        const proposeID = await dbGovernor.propose.call(
            [nft.address],
            [0],
            [inputData],
            "Proposal #1: Give grant to team",
        );
        this.proposeID = proposeID
        console.log(`proposeID ${proposeID}`)

        //address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description
        const txPropose = await dbGovernor.propose(
            [nft.address],
            [0],
            [inputData],
            "Proposal #1: Give grant to team",
        );

        assert.equal(txPropose.receipt.status, true, "propose failed !");

    });


    const delegate = async function (from,to){
        const nft = await NFTImpl.deployed();
        const tx = await nft.delegate(to, { from: from })
        assert.equal(tx.receipt.status, true, "delegate failed !");
    }

    const showNFTVotes = async function (user) {
        const nft = await NFTImpl.deployed();
        const balance = await nft.balanceOf(user)
        console.log(`user ${user} nft balance ${balance}`)

        const votes = await nft.getVotes(user)
        console.log(`user ${user} votes ${votes}`)
    }

    const printfState = async function (proposalId) {
        // enum ProposalState {
        //     Pending,
        //     Active,
        //     Canceled,
        //     Defeated,
        //     Succeeded,
        //     Queued,
        //     Expired,
        //     Executed
        // }

        //state(uint256 proposalId)

        const dbGovernor = await DBGovernor.deployed();
        const status = await dbGovernor.state(proposalId)
        console.log(`status ${status}`)

        const tk = await dbGovernor.proposalVotes(proposalId)
        //uint256 againstVotes, uint256 forVotes, uint256 abstainVotes
        console.log(`againstVotes ${tk.againstVotes} forVotes ${tk.forVotes} abstainVotes ${tk.abstainVotes}`)
    }

    const castVote = async function (proposeID, user, flags) {
        const dbGovernor = await DBGovernor.deployed();
        const nft = await NFTImpl.deployed();

        await delegate(user,user)
        // enum VoteType {
        //     Against,
        //     For,
        //     Abstain
        // }
        console.log(`proposeID ${proposeID}`)
        const castVote = await dbGovernor.castVote(
            proposeID,
            flags,
            { from: user }
        );

        assert.equal(castVote.receipt.status, true, "castVote failed !");

    }

    //function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256)
    it("testing castVote() should assert true", async function () {
        await tools.timeout(12000)

        await showNFTVotes(accounts[2])

        await castVote(this.proposeID, accounts[1], 0)

        await castVote(this.proposeID, accounts[2], 0)

        await printfState(this.proposeID)

        await tools.timeout(60000)

        await printfState(this.proposeID)
    });


})