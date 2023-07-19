const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("BiddingTest-main", (accounts) => {

  console.log(`owner address ${accounts[0]}`)

  it("testing payServiceFee() should assert true", async function () {

    const serviceFee = web3.utils.toWei('10000', 'ether')
    const bid = await BiddingTest.deployed();
    const usdt = await USDTTest.deployed();
    //platformFeeAddr
    let resultApprove = await usdt.approve(bid.address, serviceFee)
    // console.log(`approve ${resultApprove.receipt.status}`)
    assert.equal(resultApprove.receipt.status, true, "approve failed !");

    let result = await bid.payServiceFee();
    assert.equal(result.receipt.status, true, "payServiceFee failed !");
    // console.log(`result ${result.receipt}`)

    let balanceOf = await usdt.balanceOf(accounts[1]);
    console.log(`balanceOf ${balanceOf}`)
    assert.equal(balanceOf, serviceFee, "payServiceFee function testing failed !");
  });

  //TODO Fix
  it("testing minerStake() should assert true", async function () {

    const stakeAmount = web3.utils.toWei('10000', 'ether')
    const bid = await BiddingTest.deployed();
    const usdt = await USDTTest.deployed();


    const isParticipated = await bid.isParticipated(accounts[0])
    console.log(`miner status : ${isParticipated}`)
    
    if (!isParticipated) {
      console.log(`isParticipated`)
      return
    }
    expect(isParticipated).to.equal(true)
    let resultApprove = await usdt.approve(bid.address, stakeAmount)
    assert.equal(resultApprove.receipt.status, true, "approve failed !");
    console.log(`approve ${resultApprove.receipt}`)

    let expire = 1689753919

    //sign message
    let digest = ethers.solidityPackedKeccak256(["address", "uint8", "uint256", "uint256"], [accounts[0], 2, stakeAmount, expire])
    let signature = await web3.eth.sign(digest, accounts[0])
    signature = signature.substr(0, 130) + (signature.substr(130) == "00" ? "1b" : "1c");
    console.log(`${signature}`)

    let result = await bid.minerStake(stakeAmount, expire, signature);
    console.log(`result ${result.receipt}`)

    // let balanceOf =  await usdt.balanceOf(bid.address);
    // console.log(`balanceOf ${balanceOf}`)
    // assert.equal(balanceOf, serviceFee, "payServiceFee function testing failed !");
  });

  it("testing minerIntentMoney() should assert true", async function () {

    const stakeAmount = web3.utils.toWei('10000', 'ether')
    const bid = await BiddingTest.deployed();
    const usdt = await USDTTest.deployed();

    let resultApprove = await usdt.approve(bid.address, stakeAmount)
    assert.equal(resultApprove.receipt.status, true, "approve failed !");

    let expire = 1689753919
    //sign message
    let digest = ethers.solidityPackedKeccak256(["address", "uint8", "uint256", "uint256"], [accounts[0], 2, stakeAmount, expire])
    console.log(`digest : ${digest}`)

    console.log(`owner ${accounts[0]}`)
    let signature = await web3.eth.sign(digest, accounts[0])
    // console.log(`signed: ${msg}`)

    signature = signature.substr(0, 130) + (signature.substr(130) == "00" ? "1b" : "1c");

    //recover
    const recover = web3.eth.accounts.recover(digest, signature)
    expect(recover).to.equal(accounts[0])
    console.log(`recover : ${recover}`)

    //call  minerIntentMoney
    let result = await bid.minerIntentMoney(stakeAmount, expire, signature);
    assert.equal(result.receipt.status, true, "minerIntentMoney failed !");
    console.log(`result ${JSON.stringify(result.receipt.logs,null,3)}`)

    // let balanceOf =  await usdt.balanceOf(bid.address);
    // console.log(`balanceOf ${balanceOf}`)
    // assert.equal(balanceOf, serviceFee, "payServiceFee function testing failed !");

  });

});
