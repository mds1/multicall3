<img align="right" width="180" height="100" top="100" src="./assets/makerdao.png">

# Multicall • [![tests](https://github.com/mds1/multicall/actions/workflows/tests.yml/badge.svg)](https://github.com/mds1/multicall/actions/workflows/tests.yml) ![GitHub](https://img.shields.io/github/license/mds1/multicall)

Multicall aggregates results from multiple contract constant function calls.

This reduces the number of separate JSON RPC requests that need to be sent
(especially useful if using remote nodes like Infura), while also providing the
guarantee that all values returned are from the same block (like an atomic read)
and returning the block number the values are from (giving them important
context so that results from old blocks can be ignored if they're from an
out-of-date node).

There are three contracts in this repository:

- [`Multicall`](./src/Multicall.sol): The original contract containing an `aggregate` method to batch calls
- [`Multicall2`](./src/Multicall2.sol): The same as Multicall, but provides additional functions that allow calls within the batch to fail. Useful for situations where a call may fail depending on the state of the contract.
- [`Multicall3`](./src/Multicall3.sol): **This is the recommended version**. It's ABI is backwards compatible with Multicall and Multicall2, but it's cheaper to use (so you can fit more calls into a single request), and it adds an `aggregate3` method so you can specify whether calls are allowed to fail on a per-call basis. Additionally, it's deployed on every network at the same address.

These contracts can also be used to batch on-chain transactions.
If using them for this purpose, be aware these contracts are unaudited so use them at your own risk.
Additionally, **make sure you understand how `msg.sender` works when calling vs. delegatecalling to the Multicall contract, as well as the risks of using `msg.value` in a multicall**.
To learn more about the latter, see [here](https://github.com/runtimeverification/verified-smart-contracts/wiki/List-of-Security-Vulnerabilities#payable-multicall) and [here](https://samczsun.com/two-rights-might-make-a-wrong/).

You can obtain the ABI for the Multicall contracts in the following ways:

- Download the ABI from the [releases](https://github.com/mds1/multicall/releases) page
- Copy the ABI from [Etherscan](https://etherscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)
- Install [Foundry](https://github.com/gakonst/foundry/) and run `cast interface 0xcA11bde05977b3631167028862bE2a173976CA11`
- Copy the human-readable ABI [below](#human-readable-abi) for use with [ethers.js](https://github.com/ethers-io/ethers.js/).

## Deployments

### Multicall3 Contract Addresses

Multicall3 contains the following improvements over prior multicall contracts:

- Cheaper to use: fit more calls into a single request before hitting the RPC's `eth_call` gas limit.
- Backwards compatible: it can be dropped in to existing code by simply changing the address.
- Uses the same, memorable deployment address on the 50+ networks it's deployed to.

| Chain                   | [Chain ID](https://chainlist.org/) | Address                                                                                                                                                          |
| ----------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Mainnet                 | 1                                  | [0xcA11bde05977b3631167028862bE2a173976CA11](https://etherscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                       |
| Kovan                   | 42                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://kovan.etherscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                 |
| Rinkeby                 | 4                                  | [0xcA11bde05977b3631167028862bE2a173976CA11](https://rinkeby.etherscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                               |
| Görli                   | 5                                  | [0xcA11bde05977b3631167028862bE2a173976CA11](https://goerli.etherscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                |
| Ropsten                 | 3                                  | [0xcA11bde05977b3631167028862bE2a173976CA11](https://ropsten.etherscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                               |
| Sepolia                 | 11155111                           | [0xcA11bde05977b3631167028862bE2a173976CA11](https://sepolia.etherscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                               |
| Optimism                | 10                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://optimistic.etherscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                            |
| Optimism Kovan          | 69                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://kovan-optimistic.etherscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                      |
| Optimism Görli          | 420                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://blockscout.com/optimism/goerli/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                |
| Arbitrum                | 42161                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://arbiscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                        |
| Arbitrum Nova           | 42170                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://nova.arbiscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                   |
| Arbitrum Görli          | 421613                             | [0xcA11bde05977b3631167028862bE2a173976CA11](https://goerli-rollup-explorer.arbitrum.io/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)            |
| Arbitrum Rinkeby        | 421611                             | [0xcA11bde05977b3631167028862bE2a173976CA11](https://testnet.arbiscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                |
| Polygon                 | 137                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://polygonscan.com/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                    |
| Mumbai                  | 80001                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://mumbai.polygonscan.com/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                             |
| Gnosis Chain (xDai)     | 100                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://blockscout.com/xdai/mainnet/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                   |
| Avalanche               | 43114                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://snowtrace.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                       |
| Avalanche Fuji          | 43113                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://testnet.snowtrace.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                               |
| Fantom Testnet          | 4002                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://testnet.ftmscan.com/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                |
| Fantom Opera            | 250                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://ftmscan.com/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                        |
| BNB Smart Chain         | 56                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://bscscan.com/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                        |
| BNB Smart Chain Testnet | 97                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://testnet.bscscan.com/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                |
| Moonbeam                | 1284                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://moonscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                        |
| Moonriver               | 1285                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://moonriver.moonscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                              |
| Moonbase Alpha Testnet  | 1287                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://moonbase.moonscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                               |
| Harmony                 | 1666600000                         | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.harmony.one/address/0xcA11bde05977b3631167028862bE2a173976CA11?activeTab=7)                        |
| Cronos                  | 25                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://cronoscan.com/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                      |
| Fuse                    | 122                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.fuse.io/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                              |
| Flare Mainnet           | 14                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://flare-explorer.flare.network/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                  |
| Songbird Canary Network | 19                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://songbird-explorer.flare.network/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)               |
| Coston Testnet          | 16                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://coston-explorer.flare.network/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                 |
| Coston2 Testnet         | 114                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://coston2-explorer.flare.network/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                |
| Boba                    | 288                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://blockexplorer.boba.network/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                    |
| Aurora                  | 1313161554                         | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.mainnet.aurora.dev/address/0xcA11bde05977b3631167028862bE2a173976CA11)                             |
| Astar                   | 592                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://blockscout.com/astar/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                          |
| OKC                     | 66                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://www.oklink.com/en/okc/address/0xcA11bde05977b3631167028862bE2a173976CA11)                                   |
| Heco Chain              | 128                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://hecoinfo.com/address/0xcA11bde05977b3631167028862bE2a173976CA11#code)                                       |
| Metis                   | 1088                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://andromeda-explorer.metis.io/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                   |
| RSK                     | 30                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.rsk.co/address/0xcA11bde05977b3631167028862bE2a173976CA11)                                         |
| RSK Testnet             | 31                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.testnet.rsk.co/address/0xcA11bde05977b3631167028862bE2a173976CA11)                                 |
| Evmos                   | 9001                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://evm.evmos.org/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                                 |
| Evmos Testnet           | 9000                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://evm.evmos.dev/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                                 |
| Thundercore             | 108                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://viewblock.io/thundercore/address/0xcA11bde05977b3631167028862bE2a173976CA11?tab=code)                       |
| Thundercore Testnet     | 18                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer-testnet.thundercore.com/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)              |
| Oasis                   | 42262                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.emerald.oasis.dev/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                    |
| Celo                    | 42220                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.celo.org/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                             |
| Celo Alfajores Testnet  | 44787                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.celo.org/alfajores/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                   |
| Godwoken                | 71402                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://v1.gwscan.com/account/0xcA11bde05977b3631167028862bE2a173976CA11)                                           |
| Godwoken Testnet        | 71401                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://gw-explorer.nervosdao.community/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)               |
| Klaytn                  | 8217                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://scope.klaytn.com/account/0xcA11bde05977b3631167028862bE2a173976CA11)                                        |
| Milkomeda               | 2001                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer-mainnet-cardano-evm.c1.milkomeda.com/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts) |
| KCC                     | 321                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.kcc.io/en/address/0xcA11bde05977b3631167028862bE2a173976CA11)                                      |
| Velas                   | 106                                | [0xcA11bde05977b3631167028862bE2a173976CA11](https://evmexplorer.velas.com/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                         |
| Telos                   | 40                                 | [0xcA11bde05977b3631167028862bE2a173976CA11](https://www.teloscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#contract)                                |
| Step Network            | 1234                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://stepscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts#address-tabs)                      |
| Canto                   | 7700                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://evm.explorer.canto.io/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts#address-tabs)            |
| Iotex                   | 4689                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://iotexscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#transactions)                               |
| Bitgert                 | 32520                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://brisescan.com/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                                 |
| Kava                    | 2222                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.kava.io/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts)                              |
| Mantle Testnet          | 5001                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.testnet.mantle.xyz/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts#address-tabs)      |
| Shardeum Sphinx         | 8082                               | [0xcA11bde05977b3631167028862bE2a173976CA11](https://explorer.testnet.mantle.xyz/address/0xcA11bde05977b3631167028862bE2a173976CA11/contracts#address-tabs)      |
| Base Testnet            | 84531                              | [0xcA11bde05977b3631167028862bE2a173976CA11](https://goerli.basescan.org/address/0xca11bde05977b3631167028862be2a173976ca11#code)                                |

If there is a network Multicall3 is not yet deployed on, please open an issue
with a link to the block explorer. You can speed up the new deploy by sending
funds to cover the deploy cost to the deployer account: 0x05f32B3cC3888453ff71B01135B34FF8e41263F2

## Historical Deployments

Multicall3 is the recommended version for most use cases, but deployment addresses for
Multicall and Multicall2 are retained below for posterity. The Multicall smart contract
was originally intended to be used with
[Multicall.js](https://github.com/makerdao/multicall.js)
in front-end dapps. However, that library has not been updated to work with Multicall2
and Multicall3, so it will likely only work for the original Multicall contract.

### Multicall Contract Addresses

The deployed [Multicall](https://github.com/mds1/multicall/blob/master/src/Multicall.sol) contract can be found in commit [`bb309a9`](https://github.com/mds1/multicall/commit/bb309a985379c40bdbbc9a8613501732ed98bb9c) or earlier. After that commit, the contract was updated to a more recent Solidity version (with minimal improvements), primarily for compatibility with the test suite.

| Chain    | Address                                                                                                                                              |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Mainnet  | [0xeefba1e63905ef1d7acba5a8513c70307c1ce441](https://etherscan.io/address/0xeefba1e63905ef1d7acba5a8513c70307c1ce441#contracts)                      |
| Kovan    | [0x2cc8688c5f75e365aaeeb4ea8d6a480405a48d2a](https://kovan.etherscan.io/address/0x2cc8688c5f75e365aaeeb4ea8d6a480405a48d2a#contracts)                |
| Rinkeby  | [0x42ad527de7d4e9d9d011ac45b31d8551f8fe9821](https://rinkeby.etherscan.io/address/0x42ad527de7d4e9d9d011ac45b31d8551f8fe9821#contracts)              |
| Görli    | [0x77dca2c955b15e9de4dbbcf1246b4b85b651e50e](https://goerli.etherscan.io/address/0x77dca2c955b15e9de4dbbcf1246b4b85b651e50e#contracts)               |
| Ropsten  | [0x53c43764255c17bd724f74c4ef150724ac50a3ed](https://ropsten.etherscan.io/address/0x53c43764255c17bd724f74c4ef150724ac50a3ed#code)                   |
| xDai     | [0xb5b692a88bdfc81ca69dcb1d924f59f0413a602a](https://blockscout.com/poa/dai/address/0xb5b692a88bdfc81ca69dcb1d924f59f0413a602a)                      |
| Polygon  | [0x11ce4B23bD875D7F5C6a31084f55fDe1e9A87507](https://explorer-mainnet.maticvigil.com/address/0x11ce4B23bD875D7F5C6a31084f55fDe1e9A87507/contracts)   |
| Mumbai   | [0x08411ADd0b5AA8ee47563b146743C13b3556c9Cc](https://explorer-mumbai.maticvigil.com/address/0x08411ADd0b5AA8ee47563b146743C13b3556c9Cc/transactions) |
| Optimism | [0x187C0F98FEF80E87880Db50241D40551eDd027Bf](https://optimistic.etherscan.io/address/0x187C0F98FEF80E87880Db50241D40551eDd027Bf#code)                |
| Arbitrum | [0xB064Fe785d8131653eE12f3581F9A55F6D6E1ca3](https://arbiscan.io/address/0xB064Fe785d8131653eE12f3581F9A55F6D6E1ca3#code)                            |

### Multicall2 Contract Addresses

The deployed [Multicall2](https://github.com/mds1/multicall/blob/master/src/Multicall2.sol) contract can be found in commit [`bb309a9`](https://github.com/mds1/multicall/commit/bb309a985379c40bdbbc9a8613501732ed98bb9c) or earlier. After that commit, the contract was updated to a more recent Solidity version (with minimal improvements), primarily for compatibility with the test suite.

Multicall2 is the same as Multicall, but provides additional functions that allow calls within the batch to fail. Useful for situations where a call may fail depending on the state of the contract.

| Chain   | Address                                                                                                                                 |
| ------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Mainnet | [0x5ba1e12693dc8f9c48aad8770482f4739beed696](https://etherscan.io/address/0x5ba1e12693dc8f9c48aad8770482f4739beed696#contracts)         |
| Kovan   | [0x5ba1e12693dc8f9c48aad8770482f4739beed696](https://kovan.etherscan.io/address/0x5ba1e12693dc8f9c48aad8770482f4739beed696#contracts)   |
| Rinkeby | [0x5ba1e12693dc8f9c48aad8770482f4739beed696](https://rinkeby.etherscan.io/address/0x5ba1e12693dc8f9c48aad8770482f4739beed696#contracts) |
| Görli   | [0x5ba1e12693dc8f9c48aad8770482f4739beed696](https://goerli.etherscan.io/address/0x5ba1e12693dc8f9c48aad8770482f4739beed696#contracts)  |
| Ropsten | [0x5ba1e12693dc8f9c48aad8770482f4739beed696](https://ropsten.etherscan.io/address/0x5ba1e12693dc8f9c48aad8770482f4739beed696#code)      |

### Third-Party Deployments

The following addresses have been submitted by external contributors and have not been vetted by Multicall maintainers.

| Chain       | Address                                                                                                                          |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------- |
| RSK Mainnet | [0x6c62bf5440de2cb157205b15c424bceb5c3368f5](https://explorer.rsk.co/address/0x6c62bf5440de2cb157205b15c424bceb5c3368f5)         |
| RSK Testnet | [0x9e469e1fc7fb4c5d17897b68eaf1afc9df39f103](https://explorer.testnet.rsk.co/address/0x9e469e1fc7fb4c5d17897b68eaf1afc9df39f103) |
| BSC Mainnet | [0x41263cba59eb80dc200f3e2544eda4ed6a90e76c](https://bscscan.com/address/0x41263cba59eb80dc200f3e2544eda4ed6a90e76c)             |
| BSC Testnet | [0xae11C5B5f29A6a25e955F0CB8ddCc416f522AF5C](https://testnet.bscscan.com/address/0xae11c5b5f29a6a25e955f0cb8ddcc416f522af5c)     |

## Development

This repo uses [Foundry](https://github.com/gakonst/foundry) for development and testing
and git submodules for dependency management.

Clone the repo and run `forge install` to install dependencies and `forge test` to run tests.

### Foundry Setup

If you don't have Foundry installed, run the command below to get `foundryup`, the Foundry toolchain installer:

```sh
curl -L https://foundry.paradigm.xyz | bash
```

Then, in a new terminal session or after reloading your `PATH`, run `foundryup` to get the latest `forge` and `cast` binaries.

To learn more about Foundry:

- Visit the [repo](https://github.com/gakonst/foundry)
- Check out the Foundry [book](https://onbjerg.github.io/foundry-book/)
- Learn advanced ways to use `foundryup` in the [foundryup package](https://github.com/gakonst/foundry/tree/master/foundryup)
- Check out the [awesome-foundry](https://github.com/crisgarner/awesome-foundry) repo

### Gas Golfing Tricks and Optimizations

Below is a list of some of the optimizations used by Multicall3's `aggregate3` and `aggregate3Value` methods:

- In for loops, array length is cached to avoid reading the length on each loop iteration
- In for loops, the counter is incremented within an `unchecked` block
- In for loops, the counter is incremented with the prefix increment (`++i`) instead of a postfix increment (`i++`)
- All revert strings fit within a single 32 byte slot
- Function parameters use `calldata` instead of `memory`
- Instead of requiring `call.allowFailure || result.success`, we use assembly's `or()` instruction to [avoid](https://twitter.com/transmissions11/status/1501645922266091524) a `JUMPI` and `iszero()` since it's cheaper to evaluate both conditions
- Methods are given a `payable` modifier which removes a check that `msg.value == 0` when calling a method
- Calldata and memory pointers are used to cache values so they are not read multiple times within a loop
- No block data (e.g. block number, hash, or timestamp) is returned by default, and is instead left up to the caller
- The value accumulator in `aggregate3Value` is within an `unchecked` block

Read more about Solidity gas optimization tips:

- [Generic writeup about common gas optimizations, etc.](https://gist.github.com/hrkrshnn/ee8fabd532058307229d65dcd5836ddc) by [Harikrishnan Mulackal](https://twitter.com/_hrkrshnn)
- [Yul (and Some Solidity) Optimizations and Tricks](https://hackmd.io/@gn56kcRBQc6mOi7LCgbv1g/rJez8O8st) by [ControlCplusControlV](https://twitter.com/controlcthenv)

## Human-Readable ABI

Below is the human-readable ABI.
This can be directly passed into an ethers.js `Contract` or `Interface` constructor.

```typescript
const MULTICALL_ABI = [
  // https://github.com/mds1/multicall
  'function aggregate(tuple(address target, bytes callData)[] calls) payable returns (uint256 blockNumber, bytes[] returnData)',
  'function aggregate3(tuple(address target, bool allowFailure, bytes callData)[] calls) payable returns (tuple(bool success, bytes returnData)[] returnData)',
  'function aggregate3Value(tuple(address target, bool allowFailure, uint256 value, bytes callData)[] calls) payable returns (tuple(bool success, bytes returnData)[] returnData)',
  'function blockAndAggregate(tuple(address target, bytes callData)[] calls) payable returns (uint256 blockNumber, bytes32 blockHash, tuple(bool success, bytes returnData)[] returnData)',
  'function getBasefee() view returns (uint256 basefee)',
  'function getBlockHash(uint256 blockNumber) view returns (bytes32 blockHash)',
  'function getBlockNumber() view returns (uint256 blockNumber)',
  'function getChainId() view returns (uint256 chainid)',
  'function getCurrentBlockCoinbase() view returns (address coinbase)',
  'function getCurrentBlockDifficulty() view returns (uint256 difficulty)',
  'function getCurrentBlockGasLimit() view returns (uint256 gaslimit)',
  'function getCurrentBlockTimestamp() view returns (uint256 timestamp)',
  'function getEthBalance(address addr) view returns (uint256 balance)',
  'function getLastBlockHash() view returns (bytes32 blockHash)',
  'function tryAggregate(bool requireSuccess, tuple(address target, bytes callData)[] calls) payable returns (tuple(bool success, bytes returnData)[] returnData)',
  'function tryBlockAndAggregate(bool requireSuccess, tuple(address target, bytes callData)[] calls) payable returns (uint256 blockNumber, bytes32 blockHash, tuple(bool success, bytes returnData)[] returnData)',
];
```
