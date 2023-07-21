const Bidding = artifacts.require("Bidding");
const USDT = artifacts.require("Usdt");
const Financing = artifacts.require("Financing");
const NFTImpl = artifacts.require("NFT721Impl");

const Web3 = require('web3');

module.exports = async function (deployer, network, accounts) {

    let usdt = '0xed269cACd679309FAC6132F2A773B3d49535Dc87'
    if (network === 'development') {
        //deployment usdt
        await deployer.deploy(USDT, web3.utils.toWei('10000000000', 'ether'));
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

    const addrList_7 = ['0xf5A0f43a89f6F6D467a2a4e98eC3f35aBcf655B5', accounts[2], accounts[3], accounts[4], accounts[5], accounts[6], accounts[7]]
    //deploy Financing
    await deployer.deploy(Financing,
        usdt,                                                                // IERC20 usdtAddr_
        bidContract.address,                                                 // address bidding_
        accounts[0],                                                         // address platformFeeAddr_
        accounts[0],                                                         // address founderAddr_
        [2, 3, 4, 5, 6, 7, 8, 9, 22, 33],                                    // []feeList_10
        addrList_7,                                                          // []addrList_7
        [1, 864000, 4, 5, 6, 7, 8, 9, 10],                                        // []limitTimeList_9
        [10000, 1000, 2000, 7000, 24, 7, 8, 9],                              // []shareList_8
        "https://www.google.com",
        "https://www.google.com",
    )

    const FinancingContract = await Financing.deployed()
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