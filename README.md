<img align="right" width="250" height="150" top="100" src="./assets/makerdao.png">

# Multicall • [![tests](https://github.com/mds1/multicall/actions/workflows/tests.yml/badge.svg)](https://github.com/mds1/multicall/actions/workflows/tests.yml) ![GitHub](https://img.shields.io/github/license/mds1/multicall)

Multicall aggregates results from multiple contract constant function calls.

This reduces the number of separate JSON RPC requests that need to be sent
(especially useful if using remote nodes like Infura), while also providing the
guarantee that all values returned are from the same block (like an atomic read)
and returning the block number the values are from (giving them important
context so that results from old blocks can be ignored if they're from an
out-of-date node).

This smart contract is intended to be used with
[Multicall.js](https://github.com/makerdao/multicall.js) in front-end dapps.

Deployed [`Multicall`](https://github.com/mds1/multicall/blob/master/src/Multicall.sol) and [`Multicall2`](https://github.com/mds1/multicall/blob/master/src/Multicall2.sol) contracts can be found in commit [`bb309a9`](https://github.com/mds1/multicall/commit/bb309a985379c40bdbbc9a8613501732ed98bb9c) or earlier. Later (non-deployed) versions of the contracts have been upgraded to newer versions of Solidity.

### Multicall Contract Addresses
| Chain   | Address |
| ------- | ------- |
| Mainnet | [0xeefba1e63905ef1d7acba5a8513c70307c1ce441](https://etherscan.io/address/0xeefba1e63905ef1d7acba5a8513c70307c1ce441#contracts) |
| Kovan   | [0x2cc8688c5f75e365aaeeb4ea8d6a480405a48d2a](https://kovan.etherscan.io/address/0x2cc8688c5f75e365aaeeb4ea8d6a480405a48d2a#contracts) |
| Rinkeby | [0x42ad527de7d4e9d9d011ac45b31d8551f8fe9821](https://rinkeby.etherscan.io/address/0x42ad527de7d4e9d9d011ac45b31d8551f8fe9821#contracts) |
| Görli   | [0x77dca2c955b15e9de4dbbcf1246b4b85b651e50e](https://goerli.etherscan.io/address/0x77dca2c955b15e9de4dbbcf1246b4b85b651e50e#contracts) |
| Ropsten | [0x53c43764255c17bd724f74c4ef150724ac50a3ed](https://ropsten.etherscan.io/address/0x53c43764255c17bd724f74c4ef150724ac50a3ed#code) |
| xDai    | [0xb5b692a88bdfc81ca69dcb1d924f59f0413a602a](https://blockscout.com/poa/dai/address/0xb5b692a88bdfc81ca69dcb1d924f59f0413a602a) |
| Polygon | [0x11ce4B23bD875D7F5C6a31084f55fDe1e9A87507](https://explorer-mainnet.maticvigil.com/address/0x11ce4B23bD875D7F5C6a31084f55fDe1e9A87507/contracts)
| Mumbai  | [0x08411ADd0b5AA8ee47563b146743C13b3556c9Cc](https://explorer-mumbai.maticvigil.com/address/0x08411ADd0b5AA8ee47563b146743C13b3556c9Cc/transactions)
| Optimism| [0x187C0F98FEF80E87880Db50241D40551eDd027Bf](https://optimistic.etherscan.io/address/0x187C0F98FEF80E87880Db50241D40551eDd027Bf#code)
| Arbitrum| [0xB064Fe785d8131653eE12f3581F9A55F6D6E1ca3](https://arbiscan.io/address/0xB064Fe785d8131653eE12f3581F9A55F6D6E1ca3#code)

### Multicall2 Contract Addresses
Multicall2 is the same as Multicall, but provides addition functions that allow calls within the batch to fail. Useful for situations where a call may fail depending on the state of the contract.

| Chain   | Address |
| ------- | ------- |
| Mainnet | [0x5ba1e12693dc8f9c48aad8770482f4739beed696](https://etherscan.io/address/0x5ba1e12693dc8f9c48aad8770482f4739beed696#contracts) |
| Kovan   | [0x5ba1e12693dc8f9c48aad8770482f4739beed696](https://kovan.etherscan.io/address/0x5ba1e12693dc8f9c48aad8770482f4739beed696#contracts) |
| Rinkeby | [0x5ba1e12693dc8f9c48aad8770482f4739beed696](https://rinkeby.etherscan.io/address/0x5ba1e12693dc8f9c48aad8770482f4739beed696#contracts) |
| Görli   | [0x5ba1e12693dc8f9c48aad8770482f4739beed696](https://goerli.etherscan.io/address/0x5ba1e12693dc8f9c48aad8770482f4739beed696#contracts) |
| Ropsten | [0x5ba1e12693dc8f9c48aad8770482f4739beed696](https://ropsten.etherscan.io/address/0x5ba1e12693dc8f9c48aad8770482f4739beed696#code) |

### Multicall3 Contract Addresses

Multicall3 dramatically simplifies the Multicall interface by allowing the user to specify on an individual call basis whether or not it is required to succeed.

| Chain   | Address |
| ------- | ------- |
| Mainnet |  |
| Kovan   |  |
| Rinkeby |  |
| Görli   |  |
| Ropsten |  |

### Third-Party Deployments

The following addresses have been submitted by external contributors and have not been vetted by Multicall maintainers.

| Chain   | Address |
| ------- | ------- |
| RSK Mainnet   | [0x6c62bf5440de2cb157205b15c424bceb5c3368f5](https://explorer.rsk.co/address/0x6c62bf5440de2cb157205b15c424bceb5c3368f5) |
| RSK Testnet   | [0x9e469e1fc7fb4c5d17897b68eaf1afc9df39f103](https://explorer.testnet.rsk.co/address/0x9e469e1fc7fb4c5d17897b68eaf1afc9df39f103) |
| BSC Mainnet   | [0x41263cba59eb80dc200f3e2544eda4ed6a90e76c](https://bscscan.com/address/0x41263cba59eb80dc200f3e2544eda4ed6a90e76c) |
| BSC Testnet   | [0xae11C5B5f29A6a25e955F0CB8ddCc416f522AF5C](https://testnet.bscscan.com/address/0xae11c5b5f29a6a25e955f0cb8ddcc416f522af5c) |
