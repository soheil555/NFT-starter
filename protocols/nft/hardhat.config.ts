import '@nomicfoundation/hardhat-toolbox'
import { HardhatUserConfig, vars } from 'hardhat/config'

const config: HardhatUserConfig = {
  solidity: {
    compilers: [{ version: '0.8.20' }, { version: '0.4.24' }],
  },
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${vars.get(
        'ALCHEMY_API_KEY',
      )}`,
      accounts: [vars.get('PRIVATE_KEY')],
    },
  },
}

export default config
