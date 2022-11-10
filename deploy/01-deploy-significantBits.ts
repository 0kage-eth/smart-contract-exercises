import { network, getNamedAccounts, deployments } from "hardhat"
import { networkConfig } from "../helper-hardhat-config"

const deploySignificantBits = async () => {
    const { deployer } = await getNamedAccounts()
    const { deploy, log } = deployments
    const chainId = network.config.chainId || 31337

    log("deploying most significant bits contract")
    const args: any[] = []
    const bitContract = await deploy("MostSignificantBit", {
        log: true,
        from: deployer,
        args: args,
        waitConfirmations: networkConfig[chainId].blockConfirmations,
    })

    log(`deployed significant bit contract. address is ${bitContract.address}`)
}

export default deploySignificantBits

deploySignificantBits.tags = ["main", "bits"]
