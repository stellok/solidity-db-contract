// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FinancType {
    // AddrType
    struct AddrType {
        address builderAddr; //builder
        address buildInsuranceAddr; //build insurance address
        address insuranceAddr; //insurance provider
        address operationsAddr; //operation and maintenance provider
        address spvAddr; //SPV address
        address electrStakeAddr; //Electricity pledge address
        address electrAddr; //electric man
        address trustAddr; //trustManager man
    }

    AddrType public addrType;

    // FeeType
    struct FeeType {
        uint256 firstBuildFee; //first build
        uint256 remainBuildFee; //Remaining construction funds
        uint256 operationsFee; //shipping fee
        uint256 electrFee; //electricity bill
        uint256 electrStakeFee; //Pledge electricity fee
        uint256 buildInsuranceFee; //build premium //TODO unused
        uint256 insuranceFee; //warranty fee
        uint256 spvFee; //spv management fee
        uint256 publicSalePlatformFee; //public sale platform fee
        uint256 remainPlatformFee; //public sale platform fee
        uint256 trustFee; //trust management fee
    }
    FeeType public feeType;

    //time limit interval Interval
    struct LimitTimeType {
        uint256 whitelistPaymentLimitTime; //Whitelist time limit
        uint256 publicSaleLimitTime; //public sale for a limited time
        uint256 startBuildLimitTime; // Start of construction time
        uint256 bargainLimitTime; //Pick up the start time
        uint256 remainPaymentLimitTime; //Whitelist start time
        uint256 electrIntervalTime; //Power interval
        uint256 operationIntervalTime; //Time between operations
        uint256 insuranceIntervalTime; //Insurance sub-settlement time
        uint256 spvIntervalTime; //Trust interval
        uint256 trustIntervalTime; //Trust interval
    }
    LimitTimeType public limitTimeType;

    struct ShareType {
        uint256 totalShare; //Total number of shares
        uint256 financingShare; //Financing Unit
        uint256 founderShare; //Number of founder's shares
        uint256 platformShare; //Number of shares of the platform
        uint256 sharePrice; //Shares
        uint256 stakeSharePrice; //Stake share price
        uint256 firstSharePrice; //First share price
    }

    ShareType public shareType;
}