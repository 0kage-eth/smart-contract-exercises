import { BigNumber } from "ethers"
import { ethers, getNamedAccounts } from "hardhat"
import { MostSignificantBit } from "../typechain-types/contracts/MostSignificantDigit.sol"

const testSignificantScripts = async () => {
    const { deployer } = await getNamedAccounts()
    const bitContract: MostSignificantBit = await ethers.getContract("MostSignificantBit", deployer)

    const number = BigNumber.from(83)
    const output = await bitContract.findMostSignificantBit(number)

    console.log("significant bit", output)
}

testSignificantScripts()
    .then(() => {
        console.log("significant bit script executed successfully...")
        process.exit(0)
    })
    .catch((e) => {
        console.error(e)
        process.exit(1)
    })
