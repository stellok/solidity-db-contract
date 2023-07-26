const Bidding = artifacts.require("Bidding");
const USDT = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");
const NFTImpl = artifacts.require("NFT721Impl");
const tools = require('../tools/web3-utils');
const BN = require('bn.js');

module.exports = async function (deployer, network, accounts) {

    await deployer.deploy(NFTImpl, 'DB-a', 'DB-a')

    let usdt = '0xed269cACd679309FAC6132F2A773B3d49535Dc87'
    if (network === 'development' || network === 'mumbai' || network === 'myR') {
        //deployment usdt
        const init = new BN(10).pow(new BN(18)).mul(new BN('10000000000'))
        await deployer.deploy(USDT, init);
        //access information about your deployed contract instance
        const usdtContract = await USDT.deployed();
        console.log(`USDT contract : ${usdtContract.address}`)
        const usdtBalance = await usdtContract.balanceOf(accounts[0]);
        console.log(`owner : ${accounts[0]}`)
        console.log(`Owner USDT Balance: ${web3.utils.fromWei(usdtBalance, 'ether')}`)
        usdt = usdtContract.address
    }

    if (network === 'local') {
        usdt = '0xed269cACd679309FAC6132F2A773B3d49535Dc87'
    }

    //deploy bidding
    await deployer.deploy(Bidding,
        usdt,                                     // IERC20 usdtAddr_
        accounts[0],                              // address founderAddr_
        accounts[0],                              // address adminAddr_
        web3.utils.toWei('10000', 'ether'),       // service fee
        web3.utils.toWei('90000', 'ether'),       // dd fee
        accounts[0],                              // address ddAddr_
        accounts[1]                               // platformFeeAddr_
    )

    const bidContract = await Bidding.deployed()
    console.log(`bidding contract : ${bidContract.address}`)



    // IERC20 usdtAddr_,
    // IBidding bidding_,     //  招投标合约
    // address platformFeeAddr_,
    // address founderAddr_,
    // uint256[] memory feeList_,  // fees
    // address[] memory addrList_, // address  集合
    // uint256[] memory limitTimeList_,  // times  集合
    // uint256[] memory shareList_  // Share  集合

    // struct FeeType {
    //     uint256 firstBuildFee; //首次建造款
    //     uint256 remainBuildFee; //剩余建造款
    //     uint256 operationsFee; //运费费
    //     uint256 electrFee; // 电费
    //     uint256 electrStakeFee; // 质押电费
    //     uint256 buildInsuranceFee; // 建造保险费
    //     uint256 insuranceFee; // 保修费
    //     uint256 spvFee; // 信托管理费
    //     uint256 publicSalePlatformFee; // 公售平台费
    //     uint256 remainPlatformFee; // 公售平台费
    // }
    // FeeType public feeType;

    // //  限时 limit  间隔 Interval
    // struct LimitTimeType {
    //     uint256 whitelistPaymentLimitTime; // 白名单限时
    //     uint256 publicSaleLimitTime; // 公售限时
    //     uint256 startBuildLimitTime; // 开始建造时间
    //     uint256 bargainLimitTime; // 捡漏开始时间
    //     uint256 remainPaymentLimitTime; // 白名单开始时间
    //     uint256 electrIntervalTime; // 电力间隔时间
    //     uint256 operationIntervalTime; // 运维间隔时间
    //     uint256 insuranceIntervalTime; // 保险次结算时间
    //     uint256 spvIntervalTime; // 信托间隔时间
    // }

    // struct ShareType {
    //     uint256 totalShare; // 总股数
    //     uint256 financingShare; // 融资融资股
    //     uint256 founderShare; // 创始人股数
    //     uint256 platformShare; // 平台股数
    //     uint256 sharePrice; // 股价
    //     uint256 stakeSharePrice; // 质押股价
    //     uint256 firstSharePrice; // 首次股价
    //     uint256 remainSharePrice; // 补缴股价
    // }

    //  shareType.sharePrice] == shareList[shareType.stakeSharePrice] +shareList[shareType.firstSharePrice] +shareList[shareType. remainSharePrice
    //  shareType.totalShare] == shareList[shareType.financingShare] +shareList[shareType.founderShare] + shareList[shareType.platformShare

    const usdtc = await USDT.at(usdt)

    const builderAddr = accounts[2]; // 建造人
    const buildInsuranceAddr = accounts[3]; // 建造保险地址
    const insuranceAddr = accounts[4]; // 保险提供方
    const operationsAddr = accounts[2]; // 运维提供方
    const spvAddr = accounts[2]; // SPV地址
    const electrStakeAddr = accounts[2]; // 电力质押地址
    const electrAddr = accounts[2]; // 电力人



    //2, 3, 4, 5, 6, 7, 8, 9, 22, 33
    const firstBuildFee = await tools.USDTToWei(usdtc, '2')
    const remainBuildFee = await tools.USDTToWei(usdtc, '3')
    const operationsFee = await tools.USDTToWei(usdtc, '4')
    const electrFee = await tools.USDTToWei(usdtc, '5')
    const electrStakeFee = await tools.USDTToWei(usdtc, '6')
    const buildInsuranceFee = await tools.USDTToWei(usdtc, '7')
    const insuranceFee = await tools.USDTToWei(usdtc, '8')
    const spvFee = await tools.USDTToWei(usdtc, '9')
    const publicSalePlatformFee = await tools.USDTToWei(usdtc, '22')
    const remainPlatformFee = await tools.USDTToWei(usdtc, '33')


    const totalShare = 9020
    const financingShare = 20
    const founderShare = 2000
    const platformShare = 7000
    const sharePrice = await tools.USDTToWei(usdtc, '24')
    const stakeSharePrice = await tools.USDTToWei(usdtc, '7')
    const firstSharePrice = await tools.USDTToWei(usdtc, '8')
    const remainSharePrice = await tools.USDTToWei(usdtc, '9')

    //deploy Financing
    const tx = await deployer.deploy(Financing,
        usdt,                                                                                                                                                                // IERC20 usdtAddr_
        bidContract.address,                                                                                                                                                 // address bidding_
        accounts[0],                                                                                                                                                         // address platformFeeAddr_
        accounts[0],                                                                                                                                                         // address founderAddr_
        [firstBuildFee, remainBuildFee, operationsFee, electrFee, electrStakeFee, buildInsuranceFee, insuranceFee, spvFee, publicSalePlatformFee, remainPlatformFee],        // []feeList_10
        [builderAddr, buildInsuranceAddr, insuranceAddr, operationsAddr, spvAddr, electrStakeAddr, electrAddr],                                                              // []addrList_7
        [1, 864000, 4, 5, 6, 7, 8, 9, 10],                                                                                                                                   // []limitTimeList_9
        [totalShare, financingShare, founderShare, platformShare, sharePrice, stakeSharePrice, firstSharePrice, remainSharePrice],                                           // []shareList_8
        "https://metadata.artlab.xyz/01892bef-5488-84a9-a800-92d55e4e534e/",
        "https://www.google.com",
    )

    // console.log(tx)

    const FinancingContract = await Financing.deployed()

    //setFinancing
    const bResult = await bidContract.setFinancing(FinancingContract.address)
    if (!bResult.receipt.status) {
        console.log('setFinancing failed !')
    }

    console.log(`FinancingContract : ${FinancingContract.address}`)
    const share = await FinancingContract.shareType()
    console.log(`share ${JSON.stringify(share)}`)

    const receiptNFT = await FinancingContract.receiptNFT()
    const shareNFT = await FinancingContract.shareNFT()
    const u = await FinancingContract.usdt()
    console.log(`receiptNFT: ${receiptNFT} shareNFT: ${shareNFT}`)

    //deploy nft
    //string memory uri_, IERC20 usdtContract_, address owner_, uint256 feePoint_, address feeAddress_
    // await deployer.deploy(NFTImpl,
    //     'https://www.google.com',
    //     usdt,
    //     FinancingContract.address,
    //     web3.utils.toWei('0.1', 'ether'),
    //     accounts[1],
    // )
    // const nft = await NFTImpl.deployed();
    // console.log(`nft address ${nft.address}`)
    // const result = await FinancingContract.SetNft(nft.address)
    // console.log(`setNFT ${JSON.stringify(result.receipt.status)}`)
};