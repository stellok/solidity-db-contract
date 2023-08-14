const Web3 = require('web3');
const RoleTest = artifacts.require("RoleTest");
const ethers = require("ethers");
const tools = require('../tools/web3-utils');

contract("role-test", (accounts) => {

    const platAccount = accounts[1]
    const admin = accounts[2]
    const owner = accounts[3]

    const admin2 = accounts[4]

    it("testing ownerCaller() should assert true", async function () {

        //owner > admin > platform
        const reoleTest = await RoleTest.deployed();
        try {
            await reoleTest.ownerCaller({ from: admin })
        } catch (error) {
            console.log(`ownerCaller() ${error}`)
            // assert(error.message.includes("missing role"), "Expected an error with message 'Error message'.");
        }

    });

    it("testing adminCaller() should assert true", async function () {

        //owner > admin > platform
        const reoleTest = await RoleTest.deployed();
        try {
            await reoleTest.adminCaller({ from: admin })
        } catch (error) {
            console.log(`adminCaller() ${error}`)
            // assert(error.message.includes("missing role"), "Expected an error with message 'Error message'.");
        }

    });

    it("testing platFormCaller() should assert true", async function () {

        //owner > admin > platform
        const reoleTest = await RoleTest.deployed();
        try {
            await reoleTest.platFormCaller({ from: admin })
        } catch (error) {
            console.log(`platFormCaller() ${error}`)
            // assert(error.message.includes("missing role"), "Expected an error with message 'Error message'.");
        }

    });

    //grantRole
    it("testing grantRole() should assert true", async function () {

        //owner > admin > platform
        const reoleTest = await RoleTest.deployed();

        await reoleTest.grantRole(await reoleTest.PLATFORM(), admin2, { from: admin })//

        await reoleTest.grantRole(await reoleTest.ADMIN(), admin2, { from: owner })//
        // try {
        //     //grantRole(bytes32 role, address account)
        //     await reoleTest.grantRole(await reoleTest.PLATFORM, admin2, { from: owner })//
        // } catch (error) {
        //     console.log(`grantRole() ${error}`)
        //     // assert(error.message.includes("missing role"), "Expected an error with message 'Error message'.");
        // }
        // await reoleTest.platFormCaller({ from: admin2 })

    });

})