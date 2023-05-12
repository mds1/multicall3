# Multicall3 Typescript Examples

Multicall3 examples using [viem](#viem) and [ethers.js](#ethersjs).

## viem

[viem](https://viem.sh/) has native Multicall3 support which we leverage here.
This example shows how to compute Uniswap V3 pool addresses and look up their token balances.

To run the example:

- Install dependencies with `pnpm install`
- Run `pnpm ts-node viem.ts`

You can replace `pnpm` with the node package manager of your choice.

See the code and comments in `viem.ts` for more information.

## ethers.js

[ethers.js](https://docs.ethers.org/v6/) does not have native Multicall3 support so this example shows how to interact with the contract directly.
This example shows how to reverse resolve ENS names for a list of addresses.
It uses the `aggregate3` method to support reverting calls.

To run the example:

- Install dependencies with `pnpm install`
- Run `pnpm ts-node ethers.ts`

You can replace `pnpm` with the node package manager of your choice.

See the code and comments in `ethers.ts` for more information.
