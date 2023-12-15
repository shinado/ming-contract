const { network } = require("hardhat")
const { verify } = require("../utils/verify")
require("dotenv").config()

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const ming = await deployments.get("MingCoin")
    const addressOfMing = ming.address
    // const addressOfMing = '0x62a033f8C1eE5131f59D3907994cE12E020cFf5D' //address from goerli
    const endTime = 1705248000000; //15/1/2024

    log("----------------------------------------------------")
    log("Address of ming: " + addressOfMing)
    log("Deploying Funding and waiting for confirmations...")
    const funding = await deploy("Funding", {
        from: deployer,
        args: [addressOfMing, endTime],
        log: true,
        gasLimit: 5000000,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 0,
    })
    log(`Funding deployed at ${funding.address}`)

    // if (
    //     !developmentChains.includes(network.name) &&
    //     process.env.ETHERSCAN_API_KEY
    // ) {
    //     await verify(fundMe.address, [ethUsdPriceFeedAddress])
    // }
    
}

module.exports.tags = ["all", "funding"]