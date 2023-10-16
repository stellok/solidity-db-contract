const Boxv1 = artifacts.require("Boxv1");
const BoxV2 = artifacts.require("BoxV2");
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');


contract("updatable-box", (accounts) => {
    beforeEach(async function () {
        // Deploy a new Box contract for each test
        this.boxV1 = await deployProxy(Boxv1, [42], { initializer: 'store' });
    });

    it('retrieve boxV1', async function () {
        await this.boxV1.increment0();
        expect((await this.boxV1.retrieve()).toString()).to.equal('43');
    });

    it('retrieve boxV2', async function () {
        this.boxV2 = await upgradeProxy(this.boxV1.address, BoxV2)
        await this.boxV2.increment();
        // Test if the returned value is the same one
        // Note that we need to use strings to compare the 256 bit integers
        expect((await this.boxV2.retrieve()).toString()).to.equal('43');
    });

})