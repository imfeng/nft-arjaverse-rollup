// Mint a setofNFT to the privateAidrop contract
const hre = require("hardhat");

async function main() {

    
    let ERC721_ADDR = "0x741F4e1144f8Dfcab3c9b7B6a7F445FE98203b59"; // TO MODIFTY
    let AIRDROP_ADDR = "0xcA49aB231980736EdEebcDD9EF85Ff86E05EAdAF"; // TO MODIFTY
    let arjaNFT = await hre.ethers.getContractAt("ArjaGenerativeNFT", ERC721_ADDR)
    let daoName = "Arjaverse" // TO MODIFTY
    let daoRole = "Hardcore contributor" // TO MODIFTY
    let quantity = "8"; // TO MODIFTY
    let tx = await arjaNFT.mintRoleToAirdrop(daoName, daoRole, quantity, AIRDROP_ADDR);
    tx.wait();
    console.log(`# ${quantity} NFTs succefully minted and trasferred to ${AIRDROP_ADDR}` )
}

main().then(() => process.exit(0))
    .catch(e => {
        console.error(e);
        process.exit(-1);
    })