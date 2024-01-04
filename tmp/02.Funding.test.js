const { assert, expect } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");
const contractValidator = require("@sigridjin/contract-validator");

// !developmentChains.includes(network.name)
//     ? describe.skip :
describe("Funding", function () {
  let funding;
  let ming;
  let deployer;

  before(async () => {
    // const accounts = await ethers.getSigners()
    // deployer = accounts[0]
    deployer = (await getNamedAccounts()).deployer;
    await deployments.fixture(["all"]);

    const MingCoin = await deployments.get("MingCoin");
    ming = await ethers.getContractAt(MingCoin.abi, MingCoin.address);

    const Funding = await deployments.get("Funding");
    funding = await ethers.getContractAt(Funding.abi, Funding.address);

    // funding = await ethers.getContractAt("Funding", deployer);
    // ming = await ethers.getContractAt("MingCoin", deployer);
  });

  describe("funding", function () {
    it("send all tokens to Funding", async () => {
      console.log("deployer -> " + deployer);
      console.log("funding -> " + funding.address);

      const totalSupply = await ming.totalSupply();
      await ming.transfer(funding.address, totalSupply);
      const balanceOfFunding = await ming.balanceOf(funding.address);
      const balanceOfDeployer = await ming.balanceOf(deployer);

      const balance = await funding.balance()
      console.log("balance: " + balance);

      expect(balanceOfFunding).to.be.equal(totalSupply);
      expect(balanceOfDeployer).to.be.equal(0);
    });

    it("funder-0 funding-0", async () => {
      const accounts = await ethers.getSigners();
      const user1 = accounts[1];

      const sendValue = ethers.utils.parseEther("1");
      await funding.connect(user1).fund4TestOnly({ value: sendValue });
      const amountFunded = await funding.getCurrentAmountFunded(user1.address);
      expect(amountFunded).to.be.equal(sendValue);

      const balanceOfMing = await ming.balanceOf(user1);
      expect(balanceOfMing).to.be.equal(sendValue*100000000);
    });

    it("funder-0 funding-1", async () => {
      const accounts = await ethers.getSigners();
      const user1 = accounts[1];

      const sendValue = ethers.utils.parseEther("1");
      const fundingValue = ethers.utils.parseEther("2");
      await funding.connect(user1).fund({ value: sendValue });
      const amountFunded = await funding.getCurrentAmountFunded(user1.address);
      expect(fundingValue).to.be.equal(amountFunded);
    });

    it("funder-1 funding-0", async () => {
      const accounts = await ethers.getSigners();
      const user2 = accounts[2];
      const balanceOfETHb4 = await ethers.provider.getBalance(user2.address);
      console.log("eth balance before: " + balanceOfETHb4);

      const sendValue = ethers.utils.parseEther("1");
      await funding.connect(user2).fund({ value: sendValue });
      const amountFunded = await funding.getCurrentAmountFunded(user2.address);
      expect(sendValue).to.be.equal(amountFunded);

      const balance = await funding.balance();
      console.log("funding balance: " + balance);

      const balanceOfETH = await ethers.provider.getBalance(user2.address);
      console.log("eth balance after: " + balanceOfETH);
    });

    it("onFundingOver", async () => {
      //causing cannot estimate gas; transaction may fail or may require manual gas limit on --network localhost
      const totalAmountRaised = await funding.balance();
      console.log("totalAmountRaised: " + totalAmountRaised);

      const balanceOfMingBf = await ming.balanceOf(funding.address);
      console.log("balance of Ming before fund over: " + balanceOfMingBf);

      //todo get balance of WETH
      // const expectedTotalAmountRaised = ethers.utils.parseEther("3");
      // expect(totalAmountRaised).to.be.equal(expectedTotalAmountRaised);

      console.log("calling funding.onFundingOver()");
      await funding.onFundingOver();

      const accounts = await ethers.getSigners();
      const user1 = accounts[1];
      const user2 = accounts[2];

      const totalSupply = BigInt(await ming.totalSupply());

      const expectValue1 = totalSupply / 2n * 2n / 3n; //2/3
      const user1Balance = await ming.balanceOf(user1.address);
      expect(user1Balance).to.be.equal(expectValue1);

      const expectValue2 = totalSupply / 2n * 1n / 3n; //1/3
      const user2Balance = await ming.balanceOf(user2.address);
      expect(user2Balance).to.be.equal(expectValue2);

      const balanceOfMing = await ming.balanceOf(funding.address);
      console.log("balance of Ming after fund over: " + balanceOfMing);
    });
  });
});
