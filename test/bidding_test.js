const BiddingTest = artifacts.require("Bidding");
const USDTTest = artifacts.require("Usdt");


/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("BiddingTest", (accounts) => {


  console.log(`owner address ${accounts[0]}`)

  it("testing payDDFee() should assert true", async function () {

    console.log(`web3.eth ${web3.eth.fromWei('1','ether')}` )

    const bid = await BiddingTest.deployed();
    const usdt = await USDTTest.deployed();
    let resultApprove = await usdt.approve(bid.address,7)
    console.log(`approve ${resultApprove.receipt}`)
    let result = await bid.payDDFee();
    console.log(`result ${result.receipt}`)
    
    let balanceOf =  await usdt.balanceOf(bid.address);
    console.log(`balanceOf ${balanceOf}`)
    if (balanceOf == 7){
      return assert.isTrue(true);
    }else{
      return assert.isTrue(false);
    }
    
  });


  // it("testing payServiceFee() should assert true", async function () {
  //   const bid = await BiddingTest.deployed();
  //   const usdt = await USDTTest.deployed();
  //   let resultApprove = await usdt.approve(bid.address,1)
  //   console.log(`approve ${resultApprove.receipt}`)
  //   let result = await bid.payDDFee();
  //   console.log(`result ${result.receipt}`)

  //   let balanceOf =  await usdt.balanceOf(bid.address);
  //   console.log(`balanceOf ${balanceOf}`)
  //   return assert.isTrue(true);
  // });


});
