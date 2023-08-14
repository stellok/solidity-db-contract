const RoleTest = artifacts.require("RoleTest");

module.exports = async function (deployer, network, accounts) {

    console.log(network)
    const roleTestEnv = process.env.roleTest
    if (roleTestEnv) {
        await deployer.deploy(RoleTest, accounts[1], accounts[2],accounts[3])
    }

};