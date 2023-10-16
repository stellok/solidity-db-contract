const USDTTest = artifacts.require("Usdt");
const { deployProxy } = require('@openzeppelin/truffle-upgrades');


contract("updatable-usdt", (accounts) => {
    beforeEach(async function () {
        // Deploy a new Box contract for each test
        this.usdtv1 = await deployProxy(USDTTest);
    });

    it('retrieve returns a value previously initialized', async function () {
        // Test if the returned value is the same one
        // Note that we need to use strings to compare the 256 bit integers
        // expect((await this.box.retrieve()).toString()).to.equal('42');
    });

})