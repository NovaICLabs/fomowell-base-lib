const {
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const hre = require("hardhat");
const { ethers } = require("hardhat");

const { bigint } = require("hardhat/internal/core/params/argumentTypes");
const { min } = require("hardhat/internal/util/bigint");

describe("UxwapV1Router", function () {
    // let router;
    let factory, router, owner, otherAccount;

    async function deploymentFactoryWithRouterFixture() {
        let [Owner] = await ethers.getSigners();

        console.log("Owner Address is ", Owner.address);
        let OtherAccount = Owner
        console.log("Other Account Address is ", OtherAccount.address);

        const minDelay = 3600; // Example value for minimum delay
        const proposers = [Owner.address, OtherAccount.address]; // Example proposers
        const executors = [Owner.address, OtherAccount.address]; // Example executors

        let Factory = await hre.ethers.deployContract("UXwapV1Factory",
            [Owner.address, Owner.address, minDelay, proposers, executors]
        );

        console.log("Deployed Factory Done.", await Factory.getAddress());
        let Router = await hre.ethers.deployContract("UXwapV1Router", [Factory.getAddress()]);
        console.log("Deployed Router Done.", await Router.getAddress());

        const setFeeToTx = await Factory.setFeeTo(OtherAccount.address);
        const setFeeToReceipt = await setFeeToTx.wait();
        console.log(setFeeToReceipt.logs);

        const setRouterTx = await Factory.setRouter(Router.getAddress());
        const receipt = await setRouterTx.wait();
        console.log(receipt.logs);

        // console.log("Router Address is ", await router.getAddress());

        // const initialRouterTx = await router.initialize(factory.getAddress());
        // const initialRouterReceipt = await initialRouterTx.wait();
        // console.log(initialRouterReceipt.logs);
        factory = Factory;
        router = Router;
        owner = Owner;
        otherAccount = Owner;

        return { factory, router, owner, otherAccount };
    }

    // it("Should deploy the factory", async function () {
    //     const {factory, router} = await loadFixture(deploymentFactoryWithRouterFixture);
    //     console.log("Factory Address is ", await factory.getAddress());
    //     console.log("Router Address is ", await router.getAddress());
    //     expect(await factory.getAddress()).to.be.properAddress;
    //     expect(await router.getAddress()).to.be.properAddress;
    // });

    beforeEach(async function () {
        console.log("Before Each");
        await deploymentFactoryWithRouterFixture();
    });

    it("Should Create, Buy And Transfer to Use Router For Sell", async function () {
        // const {factory, router, owner,otherAccount} =
        //     await loadFixture(deploymentFactoryWithRouterFixture);

        async function extracted(name, symbol, routerAddress) {
            const tokenName = name;
            const tokenSymbol = symbol;

            const ownerBalance = await hre.ethers.provider.getBalance(owner.address);
            const otherAccountBalance = await hre.ethers.provider.getBalance(otherAccount.address);

            console.log("Owner Balance: ", ownerBalance);
            console.log("OtherAccount Balance: ", otherAccountBalance);

            const createTokenTx = await router.createToken(
                tokenName,
                tokenSymbol,
                { value: hre.ethers.parseEther("0.004") }
            );
            const createTokenReceipt = await createTokenTx.wait();

            const tokenCreatedEventTopic = hre.ethers.id("TokenCreated(address,address,string,string,address)");
            const tokenCreatedEvent = createTokenReceipt.logs.find(log => log.topics[0] === tokenCreatedEventTopic);
            if (!tokenCreatedEvent) {
                throw new Error("TokenCreated event not found");
            }

            const tokenCreatedEventArgs = router.interface.decodeEventLog("TokenCreated", tokenCreatedEvent.data, tokenCreatedEvent.topics);
            console.log("Token Created Event Args:")
            console.log(tokenCreatedEventArgs)

            const bcSwapAddress = tokenCreatedEventArgs[0]; // assuming token address is the 4th argument

            console.log("BCSwap Address is ", bcSwapAddress);

            const bondingCurve = await ethers.getContractFactory("UXwapV1BondingCurve");
            const bc = bondingCurve.attach(bcSwapAddress);

            const mintTokenEventTopic = hre.ethers.id("MintToken(string,string,uint256,address,address)");
            const mintEvent = createTokenReceipt.logs.find(log => log.topics[0] === mintTokenEventTopic);
            if (!mintEvent) {
                throw new Error("MintToken event not found");
            }

            const mintEventArgs = bc.interface.decodeEventLog("MintToken", mintEvent.data, mintEvent.topics);
            const bcTokenAddress = mintEventArgs[3];
            console.log(mintEventArgs);
            console.log("BC Token Address is ", bcTokenAddress);

            // const deadline = Math.floor(Date.now() / 1000) + 3600; // 当前时间加上1小时（3600秒）
            const deadline = Math.floor(Date.now() / 1000) + 3600;


            const bondingCurveToken = await ethers.getContractFactory("UXwapBondingCurveToken");
            const bcToken = bondingCurveToken.attach(bcTokenAddress);

            try {
                const tx = await bcToken.balanceOf(owner.address);
                console.log("Owner Balance Of = ", tx);
                // const recipet = await tx.wait();
                // console.log("Token In Router Balance: ", receipt);
            } catch (error) {
                console.error(" balance of Error:", error);
            }

            buyTx = await router.buyToken(bcSwapAddress, deadline, { value: hre.ethers.parseEther("0.001") });
            console.log("Buy Tx: ", buyTx);
            const buyReceipt = await buyTx.wait();
            console.log(buyReceipt.logs);

            // const bcToken = await ethers.getContractAt("UXwapBondingCurveToken.sol", bcTokenAddress, deployer);
            // const bcTokenAddress = await bcToken.getAddress();

            const result = await bcToken.approve(routerAddress, hre.ethers.parseEther('1000000000'));
            await result.wait();
            // const allowance = await bcToken.allowance(bcSwapAddress);
            const allowance = await bcToken.allowance(owner.address, routerAddress);
            // expect(allowance).to.equal(ethers.utils.parseUnits("100", 18));

            // console.log("BCToken Approve result: ", result);
            console.log("BCToken Approve Allowance result: ", allowance);

            console.log("Deadline Data = ", deadline)
            console.log("Owner Address = ", owner.address)
            console.log("Router Address = ", await router.getAddress())

            const bcTokenBalance = await bcToken.balanceOf(bcSwapAddress);
            const ethTokenBalance = await hre.ethers.provider.getBalance(bcSwapAddress);
            console.log(":::: BC Token Balance: ", bcTokenBalance);
            console.log(":::: ETH Token Balance: ", ethTokenBalance);

            const ownerBalance1 = await hre.ethers.provider.getBalance(owner.address);
            const otherAccountBalance1 = await hre.ethers.provider.getBalance(otherAccount.address);

            hre.ethers.provider.getTransactionCount(owner.address).then((txCount) => {
                console.log("Owner Transaction count: ", txCount);
            });

            hre.ethers.provider.getTransactionCount(otherAccount.address).then((txCount) => {
                console.log("Other Account Transaction count: ", txCount);

            });

            console.log("Owner Balance: ", ownerBalance1);
            console.log("OtherAccount Balance: ", otherAccountBalance1);

            let sellTx = await router.sellToken(bcSwapAddress, hre.ethers.parseUnits("100", 18));
            console.log("Sell Tx: ", sellTx);
            const sellReceipt = await sellTx.wait();
            console.log(sellReceipt.logs);
        }

        routerAddress = router.getAddress();
        console.log(routerAddress)

        await extracted("My Token A", "MTKA", routerAddress);
        // await extracted("My Token B", "MTKB",  routerAddress);
        // await extracted("My Token C", "MTKC",  routerAddress);
        // await extracted("My Token D", "MTKD",  routerAddress);
    });
});
