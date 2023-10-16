const Bidding = artifacts.require("Bidding");
const USDT = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");
const NFTImpl = artifacts.require("NFT721Impl");
const Dividends = artifacts.require("Operation");
const { net } = require('web3');
const tools = require('../tools/web3-utils');
const BN = require('bn.js');//Dividends
const axios = require('axios');


module.exports = async function (deployer, network, accounts) {

    if (process.env.nftSwap || process.env.DBGovernor || process.env.USDTOnly || process.env.SkipTest) {
        return
    }
    const deplorerUser = accounts[0]

    const usdtOnly = process.env.USDTOnly

    let usdt = '0xed269cACd679309FAC6132F2A773B3d49535Dc87'

    if (usdtOnly) {
        console.log(`only deployed usdt`)
        return
    } else {
        const usdtContract = await USDT.deployed();
        usdt = usdtContract.address
    }

    await deployer.deploy(NFTImpl, 'DB-a', 'DB-a', { from: deplorerUser })

    if (network === 'local') {
        usdt = '0xed269cACd679309FAC6132F2A773B3d49535Dc87'
    }

    const usdtc = await USDT.at(usdt)

    //deploy bidding
    await deployer.deploy(Bidding,
        usdt,                                     // IERC20 usdtAddr_
        accounts[0],                              // address founderAddr_
        accounts[0],                              // address adminAddr_
        await tools.USDTToWei(usdtc, '10000'),       // service fee
        await tools.USDTToWei(usdtc, '90000'),       // dd fee
        accounts[0],                              // address ddAddr_
        accounts[1],                              //  address spvAddr_
        accounts[2],
        accounts[3],                             // owner
        { from: deplorerUser }
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



    const builderAddr = accounts[2]; // 建造人
    const buildInsuranceAddr = accounts[3]; // 建造保险地址
    const insuranceAddr = accounts[4]; // 保险提供方
    const operationsAddr = accounts[2]; // 运维提供方
    const spvAddr = accounts[2]; // SPV地址
    const electrStakeAddr = accounts[2]; // 电力质押地址
    const electrAddr = accounts[2]; // 电力人
    const trustAddr = accounts[5]; // 电力人



    //2, 3, 4, 5, 6, 7, 8, 9, 22, 33
    const firstBuildFee = await tools.USDTToWei(usdtc, '2')
    const remainBuildFee = await tools.USDTToWei(usdtc, '3')
    const operationsFee = await tools.USDTToWei(usdtc, '4')
    const electrFee = await tools.USDTToWei(usdtc, '5')
    const electrStakeFee = await tools.USDTToWei(usdtc, '6')
    const buildInsuranceFee = await tools.USDTToWei(usdtc, '7')
    const insuranceFee = await tools.USDTToWei(usdtc, '8')
    const spvFee = await tools.USDTToWei(usdtc, '9')
    const publicSalePlatformFee = await tools.USDTToWei(usdtc, '2')
    const remainPlatformFee = await tools.USDTToWei(usdtc, '33')
    const trustFee = await tools.USDTToWei(usdtc, '23')



    const financingShare = 20
    const founderShare = 5
    const platformShare = 10
    const totalShare = financingShare + founderShare + platformShare

    const sharePrice = await tools.USDTToWei(usdtc, '100')
    const stakeSharePrice = await tools.USDTToWei(usdtc, '5')   //5%
    const firstSharePrice = await tools.USDTToWei(usdtc, '30')   //30%
    const remainSharePrice = await tools.USDTToWei(usdtc, '70') //70%


    const whitelistPaymentLimitTime = 1; // 白名单限时
    const publicSaleLimitTime = 60; // 公售限时
    const startBuildLimitTime = 4; // 开始建造时间
    const bargainLimitTime = 3600; // 捡漏开始时间
    const remainPaymentLimitTime = 60; // 白名单开始时间
    const electrIntervalTime = 7; // 电力间隔时间
    const operationIntervalTime = 8; // 运维间隔时间
    const insuranceIntervalTime = 9; // 保险次结算时间
    const spvIntervalTime = 10; // 信托间隔时间
    const trustIntervalTime = 10;

    //deploy Financing
    const tx = await deployer.deploy(Financing,
        usdt,                                                                                                                                                                                                   // IERC20 usdtAddr_
        bidContract.address,                                                                                                                                                                                    // address bidding_
        accounts[0],                                                                                                                                                                                            // address platformFeeAddr_
        accounts[0],                                                                                                                                                                                            // address founderAddr_
        [firstBuildFee, remainBuildFee, operationsFee, electrFee, electrStakeFee, buildInsuranceFee, insuranceFee, spvFee, publicSalePlatformFee, remainPlatformFee, trustFee],                                           // []feeList_10
        [builderAddr, buildInsuranceAddr, insuranceAddr, operationsAddr, spvAddr, electrStakeAddr, electrAddr, trustAddr],                                                                                                 // []addrList_7
        [whitelistPaymentLimitTime, publicSaleLimitTime, startBuildLimitTime, bargainLimitTime, remainPaymentLimitTime, electrIntervalTime, operationIntervalTime, insuranceIntervalTime, spvIntervalTime, trustIntervalTime],     // []limitTimeList_9
        [totalShare, financingShare, founderShare, platformShare, sharePrice, stakeSharePrice, firstSharePrice, remainSharePrice],                                                                              // []shareList_8
        "https://metadata.artlab.xyz/01892bef-5488-84a9-a800-92d55e4e534e/",
        "https://metadata.artlab.xyz/01892bef-5488-84a9-a800-92d55e4e534e/",
        30,
        100,
        { from: deplorerUser }
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

    // IERC20 usdt,
    // IERC721 nft,
    // uint256 financingFee_,
    // address financingAddr_,
    // uint256 totalShares_

    axios.defaults.baseURL = 'http://192.168.1.115:8088';
    axios.defaults.timeout = 3000;
    await axios.post('/cache/abi', { contract: usdt, abi: JSON.stringify(USDT.abi), include: 'contract' })
    await axios.post('/cache/abi', { contract: bidContract.address, abi: JSON.stringify(bidContract.abi) })
    await axios.post('/cache/abi', { contract: FinancingContract.address, abi: JSON.stringify(FinancingContract.abi) })
    await axios.post('/cache/abi', { contract: receiptNFT, abi: JSON.stringify(NFTImpl.abi) })
    await axios.post('/cache/abi', { contract: shareNFT, abi: JSON.stringify(NFTImpl.abi) })
    // await axios.post('/cache/abi', { contract: divid.address, abi: JSON.stringify(Dividends.abi) })
    console.log('regist end')
};