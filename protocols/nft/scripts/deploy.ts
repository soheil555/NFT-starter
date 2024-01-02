import { ethers } from 'hardhat'

async function main() {
  const vrfCoordinatorV2Mock = await ethers.deployContract(
    'VRFCoordinatorV2Mock',
    ['100000000000000000', '1000000000'],
  )
  await vrfCoordinatorV2Mock.waitForDeployment()
  const vrfCoordinatorV2Address = await vrfCoordinatorV2Mock.getAddress()

  console.log('[+] vrfCoordinatorV2 deployed')

  const mockV3Aggregator = await ethers.deployContract('MockV3Aggregator', [
    '18',
    '3000000000000000',
  ])
  await mockV3Aggregator.waitForDeployment()
  const mockV3AggregatorAddress = await mockV3Aggregator.getAddress()

  console.log('[+] mockV3Aggregator deployed')

  const linkToken = await ethers.deployContract('LinkToken')
  await linkToken.waitForDeployment()
  const linkTokenAddress = await linkToken.getAddress()

  console.log('[+] linkToken deployed')

  const vrfV2Wrapper = await ethers.deployContract('VRFV2Wrapper', [
    linkTokenAddress,
    mockV3AggregatorAddress,
    vrfCoordinatorV2Address,
  ])
  await vrfV2Wrapper.waitForDeployment()
  const vrfV2WrapperAddress = await vrfV2Wrapper.getAddress()

  console.log('[+] vrfV2Wrapper deployed')

  let tx = await vrfV2Wrapper.setConfig(
    '60000',
    '52000',
    '10',
    '0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc',
    '10',
  )
  await tx.wait()

  tx = await vrfCoordinatorV2Mock.fundSubscription('1', '10000000000000000000')
  await tx.wait()

  const nft = await ethers.deployContract('NFT', [
    linkTokenAddress,
    vrfV2WrapperAddress,
  ])
  await nft.waitForDeployment()
  const nftAddress = await nft.getAddress()

  console.log('[+] nft deployed')

  await linkToken.transfer(nftAddress, '10000000000000000000')

  tx = await nft.create()
  await tx.wait()

  const requestId = await nft.lastRequestId()

  tx = await vrfCoordinatorV2Mock.fulfillRandomWords(
    requestId,
    vrfV2WrapperAddress,
  )
  await tx.wait()

  const result = await nft.getRequestStatus(requestId)

  console.log(result)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
