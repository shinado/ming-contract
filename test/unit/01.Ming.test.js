const { assert, expect } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");

// !developmentChains.includes(network.name)
//     ? describe.skip :
describe("Ming", function () {
  let ming;
  let deployer;
  const decimals = 1000000000000000000n;

  before(async () => {
    // const accounts = await ethers.getSigners()
    // deployer = accounts[0]
    deployer = (await getNamedAccounts()).deployer;
    await deployments.fixture(["all"]);

    const myContract = await deployments.get("MingCoin");
    ming = await ethers.getContractAt(myContract.abi, myContract.address);

    // ming = await ethers.getContractAt("MingCoin", deployer);
  });

  describe("basic functions", function () {
    it("mint", async () => {
      await ming.mint();
      const balanceOfDeployer = await ming.balanceOf(deployer);
      expect(balanceOfDeployer).to.be.equal(444444n * decimals);
    });

    it("batch mint", async () => {
      // const accounts = await ethers.getSigners();
      // const user1 = accounts[1];
      // const user2 = accounts[2];

      const sendValue = ethers.utils.parseEther("1");
      await ming.batchMint({ value: sendValue });
      const balance1 = await ming.balanceOf(deployer);

      expect(balance1).to.be.equal((106666666n + 444444n) * decimals);
    });
  });

  describe("burning", function () {
    it("burn", async () => {
      const tx = await ming.burn(
        "George Washington",
        1000n * decimals,
        "hello world"
      );

      // Wait for the transaction to be confirmed
      await tx.wait();
      const address = await ming.getAddressByName("George Washington");
      console.log("address: ", address);

      await ming.burnToAddress(address, 3000n * decimals, "bilibili");

      const history = await ming.getBurningHistory(address);
      expect(history.length).to.be.equal(2);
    });
  });
});
