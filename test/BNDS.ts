import { expect } from "chai";
import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";


describe("Transfer", function () {
    let owner: SignerWithAddress;
    let p1: SignerWithAddress;
    let p2: SignerWithAddress;
    let p3: SignerWithAddress;
    let ERC20Token
    let erc20: Contract


    beforeEach(async function () {
        ERC20Token = await ethers.getContractFactory("contracts/BNDS.sol:BNDS");
        [owner, p1, p2,p3] = await ethers.getSigners();

        erc20 = await ERC20Token.deploy("bnds", "BNDS", "1000000000000000000000000");
    });

    it("owner转账给p1", async function () {
        // owner
        expect(await erc20.owner()).to.equal(owner.address);

        // transfer to p1
        let t1 = await erc20.transfer(p1.address, 10000);
        let ownerBalance = await erc20.balanceOf(owner.address)
        expect(await erc20.balanceOf(p1.address)).to.equal(10000);
        expect(await erc20.balanceOf(owner.address)).to.equal("999999999999999999990000");

    });

    it("设置手续地址", async function () {
        expect(await erc20.feeAddress()).to.equal("0x0000000000000000000000000000000000000000");

        await erc20.transfer(p3.address, 10000);
        expect(await erc20.balanceOf(p3.address)).to.equal(10000);

        await erc20.setFeeAddress(p1.address);
        expect(await erc20.feeAddress()).to.equal(p1.address);
        await expect(erc20.connect(p1).setFeeAddress(p1.address)).to .be .revertedWith("Ownable: caller is not the owner");

        expect(await erc20.owner()).to.equal(owner.address);
        // transfer to p1
        expect(await erc20.balanceOf(p1.address)).to.equal(0);
        await erc20.transfer(p1.address, 10000);
        expect(await erc20.balanceOf(p1.address)).to.equal(10000);

        // p1 to p2
        await erc20.connect(p1).transfer(p2.address, 8500);
        expect(await erc20.balanceOf(p1.address)).to.equal(2775);
        expect(await erc20.balanceOf(p2.address)).to.equal(7225);


        // 设置白名单后
        await erc20.setWhitelistList(p2.address, true);
        expect ( await erc20.whitelistList(p2.address)).to.equal(true);
        await erc20.connect(p2).transfer(p3.address, 5000);
        expect(await erc20.balanceOf(p2.address)).to.equal(2225);
        expect(await erc20.balanceOf(p3.address)).to.equal(15000);

        await erc20.connect(p3).transfer(p2.address, 10000);
        expect(await erc20.balanceOf(p2.address)).to.equal(10725);

    });

    it("转移新的管理员", async function () {
        await erc20.transferOwnership(p2.address);
        expect ( await erc20.owner()).to.equal(p2.address);
    });





});
