const BiddingTest = artifacts.require("Bidding");
const USDT = artifacts.require("USDT");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("BiddingTest", (accounts) => {
  it("should assert true", async function () {
    await BiddingTest.deployed();
    return assert.isTrue(true);
  });
});
