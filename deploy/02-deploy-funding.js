const { network } = require("hardhat")
const { verify } = require("../utils/verify")
require("dotenv").config()

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    //should always used hard coded address
    // const ming = await deployments.get("MingCoin")
    // const addressOfMing = ming.address
    const addressOfMing = '0xee04E68E35d72a5e8eF9110A095d4172c0F59aE4' //address from goerli
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