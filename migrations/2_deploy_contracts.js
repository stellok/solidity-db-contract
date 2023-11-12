const Bidding = artifacts.require("Bidding");
const USDT = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");
const NFTImpl = artifacts.require("NFT721Impl");
const Dividends = artifacts.require("Operation");
const { net } = require('web3');
const tools = require('../tools/web3-utils');
const BN = require('bn.js');//Dividends
const axios = require('axios');
require('dotenv').config();
const { NFT_SERVER } = process.env;


module.exports = async function (deployer, network, accounts) {
    if (process.env.nftSwap || process.env.DBGovernor || process.env.USDTOnly || process.env.SkipTest || process.env.referral) {
        return
    }
    const deplorerUser = accounts[0]

    let usdt = '0xed269cACd679309FAC6132F2A773B3d49535Dc87'
    const usdtContract = await USDT.deployed();
    usdt = usdtContract.address


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
        10,//uint256 subscribeMax_,
        100,//uint256 userMax_
        { from: deplorerUser }
    )

    const bidContract = await Bidding.deployed()
    console.log(`bidding contract : ${bidContract.address}`)



    // IERC20 usdtAddr_,
    // IBidding bidding_,     //  Tender Contracts
    // address platformFeeAddr_,
    // address founderAddr_,
    // uint256[] memory feeList_,        // fees
    // address[] memory addrList_,       // address  
    // uint256[] memory limitTimeList_,  // times 
    // uint256[] memory shareList_       // Share

    // struct FeeType {
    //     uint256 firstBuildFee; //The first construction model
    //     uint256 remainBuildFee; //The remaining construction money
    //     uint256 operationsFee; //Shipping costs
    //     uint256 electrFee; // Electricity
    //     uint256 electrStakeFee; // Pledge electricity bills
    //     uint256 buildInsuranceFee; // Construction insurance premiums
    //     uint256 insuranceFee; // Warranty Fee
    //     uint256 spvFee; // Trust administration fees
    //     uint256 publicSalePlatformFee; // Public sale platform fee
    //     uint256 remainPlatformFee; // Public sale platform fee
    // }
    // FeeType public feeType;

    // struct LimitTimeType {
    //     uint256 whitelistPaymentLimitTime; // The whitelist is time-limited
    //     uint256 publicSaleLimitTime; // Public sale for a limited time
    //     uint256 startBuildLimitTime; // Start of construction time
    //     uint256 bargainLimitTime; // Pick up the start time
    //     uint256 remainPaymentLimitTime; // The start time of the whitelist
    //     uint256 electrIntervalTime; // Electricity intervals
    //     uint256 operationIntervalTime; // O&M interval
    //     uint256 insuranceIntervalTime; // The time of settlement of the insurance
    //     uint256 spvIntervalTime; // Trust interval
    // }

    // struct ShareType {
    //     uint256 totalShare; // Total number of shares
    //     uint256 financingShare; // Financing Stocks
    //     uint256 founderShare; // Number of shares of the founder
    //     uint256 platformShare; // The number of shares on the platform
    //     uint256 sharePrice; // Shares
    //     uint256 stakeSharePrice; // Stake share price
    //     uint256 firstSharePrice; // Initial share price
    //     uint256 remainSharePrice; //Top-up share price
    // }

    //  shareType.sharePrice] == shareList[shareType.stakeSharePrice] +shareList[shareType.firstSharePrice] +shareList[shareType. remainSharePrice
    //  shareType.totalShare] == shareList[shareType.financingShare] +shareList[shareType.founderShare] + shareList[shareType.platformShare



    const builderAddr = accounts[2]; // Builders
    const buildInsuranceAddr = accounts[3]; // Build an insured address
    const insuranceAddr = accounts[4]; // Insurance Providers
    const operationsAddr = accounts[2]; // O&M providers
    const spvAddr = accounts[2]; // SPV address
    const electrStakeAddr = accounts[2]; // Power pledge address
    const electrAddr = accounts[2]; //
    const trustAddr = accounts[5]; //



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
    const firstSharePrice = await tools.USDTToWei(usdtc, '30')   //100%
    const remainSharePrice = await tools.USDTToWei(usdtc, '70')   //100%


    const whitelistPaymentLimitTime = 1; // The whitelist is time-limited
    const publicSaleLimitTime = 60; // Public sale for a limited time
    const startBuildLimitTime = 4; // Start of construction time
    const bargainLimitTime = 3600; // Pick up the start time
    const remainPaymentLimitTime = 60; // The start time of the whitelist
    const electrIntervalTime = 7; // Electricity intervals
    const operationIntervalTime = 8; // O&M interval
    const insuranceIntervalTime = 9; // The time of settlement of the insurance
    const spvIntervalTime = 10; // Trust interval
    const trustIntervalTime = 10;

    //deploy Financing
    const tx = await deployer.deploy(Financing,
        usdt,                                                                                                                                                                                                            // IERC20 usdtAddr_
        bidContract.address,                                                                                                                                                                                             // address bidding_
        accounts[0],                                                                                                                                                                                                     // address platformFeeAddr_
        accounts[0],                                                                                                                                                                                                     // address founderAddr_
        [firstBuildFee, remainBuildFee, operationsFee, electrFee, buildInsuranceFee, insuranceFee, spvFee, publicSalePlatformFee, remainPlatformFee, trustFee],                                                           // []feeList_10
        [builderAddr, buildInsuranceAddr, insuranceAddr, operationsAddr, spvAddr, electrAddr, trustAddr],                                                                                                                   // []addrList_7
        [whitelistPaymentLimitTime, publicSaleLimitTime, startBuildLimitTime, bargainLimitTime, remainPaymentLimitTime, electrIntervalTime, operationIntervalTime, insuranceIntervalTime, spvIntervalTime, trustIntervalTime],     // []limitTimeList_9
        [totalShare, financingShare, founderShare, platformShare, sharePrice, stakeSharePrice, firstSharePrice, remainSharePrice],                                                                                                               // []shareList_8
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

    // IERC20 usdt,
    // IERC721 nft,
    // uint256 financingFee_,
    // address financingAddr_,
    // uint256 totalShares_


    axios.defaults.baseURL = `${NFT_SERVER}`
    axios.defaults.timeout = 3000;
    await axios.post('/cache/abi', { contract: usdt, abi: JSON.stringify(USDT.abi), include: 'contract' })
    await axios.post('/cache/abi', { contract: bidContract.address, abi: JSON.stringify(bidContract.abi) })
    await axios.post('/cache/abi', { contract: FinancingContract.address, abi: JSON.stringify(FinancingContract.abi) })
    await axios.post('/cache/abi', { contract: receiptNFT, abi: JSON.stringify(NFTImpl.abi) })
    // await axios.post('/cache/abi', { contract: divid.address, abi: JSON.stringify(Dividends.abi) })
    console.log('regist end')
};