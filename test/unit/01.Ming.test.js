const { assert, expect } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");

// !developmentChains.includes(network.name)
//     ? describe.skip :
describe("Ming", function () {
  let ming;
  let deployer;

  before(async () => {
    // const accounts = await ethers.getSigners()
    // deployer = accounts[0]
    deployer = (await getNamedAccounts()).deployer;
    await deployments.fixture(["all"]);

    const myContract = await deployments.get("MingCoin");
    ming = await ethers.getContractAt(myContract.abi, myContract.address);

    // ming = await ethers.getContractAt("MingCoin", deployer);
  });

  describe("constructor", function () {
    it("burn", async () => {
      console.log("address of ming: " + ming.address);
      const address = await ming.burn("北京大张伟", 12);
      console.log("address:" + address);
      expect(address).to.be.equal("kkkkk");
      // const balanceOfDeployer = await ming.balanceOf(deployer);
      // const totalSupply = await ming.totalSupply();
      // expect(balanceOfDeployer).to.be.equal(totalSupply);
    });

    // it("transfer", async() => {
    //   const accounts = await ethers.getSigners();
    //   const user1 = accounts[1];
    //   const user2 = accounts[2];

    //   await ming.transfer(user1.address, 364444444444444080000n)
    //   await ming.transfer(user2.address, 182222222222222040000n)

    //   const user1Balance = await ming.balanceOf(user1.address);
    //   expect(user1Balance).to.be.equal(364444444444444080000n);

    //   const user2Balance = await ming.balanceOf(user2.address);
    //   expect(user2Balance).to.be.equal(182222222222222040000n);

    //   const balanceOfMing = await ming.balanceOf(deployer);
    //   console.log("balance of Ming: " + balanceOfMing);
    // })
  });
});
