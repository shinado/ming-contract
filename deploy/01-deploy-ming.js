const { network, ethers } = require("hardhat")
const { verify } = require("../utils/verify")
require("dotenv").config()

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    
    const provider = ethers.getDefaultProvider('goerli'); // or another network
    const balanceWei = await provider.getBalance(deployer);

    log("----------------------------------------------------")
    log("Deploying MingCoin and waiting for confirmations...")
    log("Deployer..." + deployer)
    log("balance..." + balanceWei)

    const ming = await deploy("MingCoin", {
        from: deployer,
        args: [],
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    log(`MingCoin deployed at ${ming.address}`)
}

module.exports.tags = ["all", "ming"]