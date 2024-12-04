const { expect } = require("chai");
const hre = require("hardhat");

describe("TokenFactory", function(){
    it("Should create the memetoken successfully", async function(){
        const tokenFactoryct = await hre.ethers.deployContract("TokenFactory");
        const tx = await tokenFactoryct.createMemeToken("dogecoin", "DOGE", "This is a doge token", "image.png", {
            value: hre.ethers.parseEther("0.0001")
        })
    })

    it("Should let the user purchase the memetoken", async function(){
        const tokenFactoryct = await hre.ethers.deployContract("TokenFactory");
        const tx = await tokenFactoryct.createMemeToken("dogecoin", "DOGE", "This is a doge token", "image.png", {
            value: hre.ethers.parseEther("0.0001")
        })
        const memeTokenAddress = await tokenFactoryct.memeTokenAddresses(0)

        const tx2 = await tokenFactoryct.buyMemeToken(memeTokenAddress, 800000)
    })
})