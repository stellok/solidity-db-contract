#!/bin/bash
set -e

truffle test -g BiddingTest-MinerIntentMoney
truffle test -g BiddingTest-paydd 
truffle test -g BiddingTest-main
truffle test -g BiddingTest-planStake
truffle test -g BiddingTest-subscribe
truffle test -g FinancingTest-whilepay-2-remain-success
truffle test -g FinancingTest-whilepay-2-remain-fail
truffle test -g FinancingTest-whilepay-publicSale
truffle test -g FinancingTest-whilepay-nomal
truffle test -g BiddingTest-payMinerToSpv
truffle test -g FinancingTest-whilepay-Receive