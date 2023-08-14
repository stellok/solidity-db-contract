
const ethers = require("ethers");


module.exports = async function (callback) {



    //0x4Fa5bf4812DDb8C7f54aeF1bFB625b7EE5ED28Fc ec853128 0x063bc648f41422e15c8bC088b55fD470538F82F8 1 5000000000000000000 1000000000000000000 1691553600

    const packed = ethers.solidityPacked(["address", "string", "address", "uint8", "uint256", "uint256", "uint256"], ['0x4Fa5bf4812DDb8C7f54aeF1bFB625b7EE5ED28Fc', 'ec853128', '0x063bc648f41422e15c8bC088b55fD470538F82F8',1, '5000000000000000000','1000000000000000000', 1691553600])
    console.log(`packed ${packed}`)



}

