const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("BiddingTest", (accounts) => {


  console.log(`owner address ${accounts[0]}`)

  it("testing payDDFee() should assert true", async function () {

    const ddFee = web3.utils.toWei('90000', 'ether')
    const bid = await BiddingTest.deployed();
    const usdt = await USDTTest.deployed();
    let resultApprove = await usdt.approve(bid.address, ddFee)
    assert.equal(resultApprove.receipt.status, true, "approve failed !");

    const isddFee = await bid.isfDdFee()
    console.log(`isfDdFee ${isddFee}`)
    // console.log(`approve ${JSON.stringify(resultApprove.receipt)}`)
    let result = await bid.payDDFee();
    assert.equal(result.receipt.status, true, "payDDFee failed !");

    // console.log(`result ${result.receipt}`)
    let balanceOf = await usdt.balanceOf(bid.address);
    console.log(`balanceOf ${balanceOf}`)
    assert.equal(balanceOf, ddFee, "payDDFee function testing failed !");

  });


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

  it("testing minerStake() should assert true", async function () {

    const stakeAmount = web3.utils.toWei('10000', 'ether')
    const bid = await BiddingTest.deployed();
    const usdt = await USDTTest.deployed();

    let resultApprove = await usdt.approve(bid.address, stakeAmount)
    assert.equal(resultApprove.receipt.status, true, "payServiceFee failed !");
    console.log(`approve ${resultApprove.receipt}`)

    //sign message
    let encodePacked =  ethers.utils.concat([ ethers.utils.toUtf8Bytes('11'), ethers.utils.toUtf8Bytes('22'), ethers.utils.toUtf8Bytes('33')])
    let digest = ethers.utils.keccak256(encodePacked)
    const msg = await web3.eth.sign(digest, accounts[0])
    console.log(`${msg}`)

    let result = await bid.minerStake(stakeAmount, '1689753919', msg);
    console.log(`result ${result.receipt}`)

    // let balanceOf =  await usdt.balanceOf(bid.address);
    // console.log(`balanceOf ${balanceOf}`)
    // assert.equal(balanceOf, serviceFee, "payServiceFee function testing failed !");
  });

  it("testing subscribe() should assert true", async function () {
    //subscribe
    const bid = await BiddingTest.deployed();
    const usdt = await USDTTest.deployed();

    // uint256 financingShare_,
    // uint256 stakeSharePrice_,
    // uint256 subscribeTime_,
    // uint256 subscribeLimitTime_

    let subBegin = await bid.startSubscribe(10000, 20, 1689581119, 1689753919);
    assert.equal(subBegin.receipt.status, true, "startSubscribe failed !");


    let stock = 10;

    let financingShare = await bid.financingShare();
    let stakeSharePrice = await bid.stakeSharePrice();
    let totalSold = await bid.totalSold()

    if (financingShare * 2 - totalSold < stock) {
      stock = financingShare * 2 - totalSold;
    }

    let resultApprove = await usdt.approve(bid.address, web3.utils.toWei(web3.utils.toBN(stock * stakeSharePrice), 'ether'))
    assert.equal(resultApprove.receipt.status, true, "approve failed !");

    let sub = await bid.subscribe(10)
    assert.equal(sub.receipt.status, true, "subscribe failed !");

    console.log(`${JSON.stringify(sub.receipt.logs)}`)
  });

});
