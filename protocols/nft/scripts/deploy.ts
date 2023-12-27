import hre from 'hardhat'

async function main() {
  const svg = `<svg xlmns="http://www.w3.org/2000/svg" width="100" height="100"><circle cx="50" cy="50" r="40" stroke="green" stroke-width="4" fill="yellow" /></svg>`
  const nft = await hre.viem.deployContract('NFT')

  const base64 = await nft.read.formatTokenURI([svg])

  console.log(base64)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
