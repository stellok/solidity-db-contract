const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
var tools = require('../tools/web3-utils');

// ---- param ----- 
// companyType role,
// uint256 totalAmount,
// uint256 stakeAmount,
// uint256 expire,
// bytes memory signature

// ----- sign ------
// _msgSender(),
// signType.planStake,
// role,
// totalAmount,
// stakeAmount,
// expire


// enum companyType {
//     invalid,
//     builder,
//     builderInsurance,
//     insurance,
//     operations
// }

contract("BiddingTest-planStake", (accounts) => {
    let user = accounts[4]
    let owner = accounts[0]
    let role = 1
    let stakeAmount = web3.utils.toWei('1000', 'ether'), totalAmount = stakeAmount

    before(async function () {
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        //transfer usdt
        console.log(`\n using account ${user} as user ! `)
        const amount = await tools.USDTToWei(usdt, '100000')
        const result = await usdt.transfer(user, amount)
        assert.equal(result.receipt.status, true, "transfer usdt failed !");
        const balance = await usdt.balanceOf(user)
        console.log(` ${user} ${web3.utils.fromWei(balance, 'ether')} USDT \n`)

    });

    it("testing planStake() should assert true", async function () {
        //subscribe
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        let expire = 1690616038


        //sign message
        let digest = ethers.solidityPackedKeccak256(["address", "string","address", "uint8", "uint256", "uint256", "uint256"], [bid.address, tools.getsignature(bid, 'planStake'),user, role, totalAmount, stakeAmount, expire])
        console.log(`digest : ${digest}`)

        console.log(`owner ${accounts[0]}`)
        let signature = await web3.eth.sign(digest, accounts[0])
        // console.log(`signed: ${msg}`)

        signature = signature.substr(0, 130) + (signature.substr(130) == "00" ? "1b" : "1c");

        //recover
        const recover = web3.eth.accounts.recover(digest, signature)
        expect(recover).to.equal(accounts[0])
        console.log(`recover : ${recover}`)

        //
        let resultApprove = await usdt.approve(bid.address, web3.utils.toWei(web3.utils.toBN(stakeAmount), 'ether'), { from: user })
        assert.equal(resultApprove.receipt.status, true, "approve failed !");

        let sub = await bid.planStake(role, totalAmount, stakeAmount, expire, signature, { from: user })
        assert.equal(sub.receipt.status, true, "planStake failed !");

        let balanceOf = await usdt.balanceOf(bid.address);
        console.log(`Bid usdt balance : ${web3.utils.fromWei(balanceOf, 'ether')}`)

        assert.equal(balanceOf, totalAmount, "usdt balance transfer failed !");

        console.log(`logs: ${JSON.stringify(sub.receipt.logs, null, 3)}`)
    });

    //unPlanStake
    it("testing unPlanStake() should assert true", async function () {
        //subscribe
        const bid = await BiddingTest.deployed();
        const usdt = await USDTTest.deployed();

        let origUsdtBalance = await usdt.balanceOf(user);

        console.log(`origUsdtBalance : ${web3.utils.fromWei(origUsdtBalance, 'ether')}`)

        let sub = await bid.unPlanStake(role, { from: owner })
        assert.equal(sub.receipt.status, true, "planStake failed !");

        let balanceOf = await usdt.balanceOf(user);
        console.log(`Now balance : ${web3.utils.fromWei(balanceOf, 'ether')}`)

        assert.equal(balanceOf.toString(), web3.utils.toBN(totalAmount).add(origUsdtBalance).toString(), "withdraw failed !");

        console.log(`logs: ${JSON.stringify(sub.receipt.logs, null, 3)}`)
    });
})