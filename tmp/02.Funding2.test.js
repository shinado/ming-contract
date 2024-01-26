const { assert, expect } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
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
  });

  describe("funding", function () {
    it("send all tokens to Funding", async () => {
      console.log("deployer -> " + deployer);
      console.log("funding -> " + funding.address);

      const totalSupply = await ming.totalSupply();
      await ming.transfer(funding.address, totalSupply);
      const balanceOfFunding = await ming.balanceOf(funding.address);
      const balanceOfDeployer = await ming.balanceOf(deployer);

      const balance = await funding.balance();
      console.log("balance: " + balance);

      expect(balanceOfFunding).to.be.equal(totalSupply);
      expect(balanceOfDeployer).to.be.equal(0);
    });

    it("funding-0", async () => {
      await funding.getCurrentAmountFunded(
        "0x820638ecd57B55e51CE6EaD7D137962E7A201dD9"
      );
      console.log("called getCurrentAmountFunded(1).");

      const accounts = await ethers.getSigners();
      const user1 = accounts[1];

      const sendValue = ethers.utils.parseEther("1");

      const fundingUser1 = await funding.connect(user1);
      await fundingUser1.fund4TestOnly({ value: sendValue });

      await funding.getCurrentAmountFunded(
        "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
      );
      console.log("called getCurrentAmountFunded(2).");

      const user1Address = await user1.getAddress();
      console.log("fundingUser1: " + fundingUser1.address);
      console.log("user1Address: " + user1Address);

      const amountFunded = await funding.getCurrentAmountFunded(user1Address);
      expect(amountFunded).to.be.equal(sendValue);
      console.log("called getCurrentAmountFunded(3) -> " + amountFunded);

      const balanceOfMing = await ming.balanceOf(user1Address);

      // Use BigNumber for the comparison
      const expectedBalance = ethers.BigNumber.from(sendValue).mul(
        ethers.BigNumber.from("100000000")
      );
      // Use BigNumber comparison methods
      expect(balanceOfMing.eq(expectedBalance)).to.be.true;
    });
  });
});
