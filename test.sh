#!/bin/bash
set -e

truffle compile

truffle test -g BiddingTest-MinerIntentMoney --compile-none -b -t
truffle test -g BiddingTest-paydd --compile-none -b -t
truffle test -g BiddingTest-main --compile-none -b -t
truffle test -g BiddingTest-planStake --compile-none -b -t
truffle test -g BiddingTest-subscribe --compile-none -b -t
truffle test -g FinancingTest-whilepay-2-remain-success --compile-none -b -t
truffle test -g FinancingTest-whilepay-2-remain-fail --compile-none -b -t
truffle test -g FinancingTest-whilepay-publicSale --compile-none -b -t
truffle test -g FinancingTest-whilepay-nomal --compile-none -b -t
truffle test -g BiddingTest-payMinerToSpv --compile-none -b -t
truffle test -g FinancingTest-whilepay-Receive --compile-none -b -t
USDTOnly=true truffle test -g PointsSystem --compile-none -b -t