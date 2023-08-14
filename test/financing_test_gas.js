const Web3 = require('web3');
const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");
const ethers = require("ethers");
const tools = require('../tools/web3-utils');
const Financing = artifacts.require("Financing");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("BiddingTest-TestGAS", (accounts) => {


  // it("testing testGas() should assert true", async function () {

  //   const financing = await Financing.deployed();
  //   const tx = await financing.testGas.estimateGas(100)
  //   console.log(tx)

  //   const org = tools.toBN(tx).mul(tools.toBN(web3.utils.toWei('89', 'gwei')))
  //   console.log(web3.utils.fromWei(org, 'ether'))

  // });

  it("testing testGasGO() should assert true", async function () {

    const financing = await Financing.deployed();
    const tx = await financing.testGas(100)
    console.log(`gasUsed: ${tx.gasUsed} effectiveGasPrice: ${tx.effectiveGasPrice}`)
    
  });
});
