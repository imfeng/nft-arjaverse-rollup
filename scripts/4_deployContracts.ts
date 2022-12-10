const hre = require("hardhat");
import { BigNumber } from "@ethersproject/bignumber";
import {getMerkleTreeFromPublicListOfCommitments, getMerkleRoot} from "../utils/TestUtils";
import { PrivateAirdrop } from "../typechain";

/**
 * Deploys a test set of contracts: ERC721, Verifier, PrivateAirdrop
 */
async function main() {
    
    
    let NUM_ERC721_PER_REDEMPTION = 1;
    let inputFileName = "./public/publicCommitments.txt"
    let treeHeight = 5

    let mt = getMerkleTreeFromPublicListOfCommitments(inputFileName, treeHeight)
    let merkleTreeRoot = getMerkleRoot(mt)

    // DEPLOY ERC721 contract 
    let arjaNFTFactory = await hre.ethers.getContractFactory("ArjaGenerativeNFT")
    let arjaNFT = await arjaNFTFactory.deploy()
    console.log(`ERC721 address: ${arjaNFT.address}`)
    for (let index = 0; index < 64; index++) {
        console.log({
            index
        })
        await arjaNFT.mint();
    }

    // // DEPLOY PLONK VERIFIER
    // let plonkFactory = await hre.ethers.getContractFactory("PlonkVerifier")
    // let plonk = await plonkFactory.deploy()
    // console.log(`Plonk Verifier contract address: ${plonk.address}`)

    // // DEPLOY PRIVATE AIRDROP
    // let mainFactory = await hre.ethers.getContractFactory("PrivateAirdrop")
    // let privateAirdrop: PrivateAirdrop = (
    //     await mainFactory.deploy(
    //         arjaNFT.address,
    //         BigNumber.from(NUM_ERC721_PER_REDEMPTION),
    //         plonk.address,
    //         merkleTreeRoot)) as PrivateAirdrop
    // console.log(`PrivateAirdrop contract address: ${privateAirdrop.address} merkleTree root: ${merkleTreeRoot}`)
}

main()
    .then(() => process.exit(0))
    .catch(e => {
        console.error(e);
        process.exit(1);
    })