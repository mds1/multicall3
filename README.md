Multicall aggregates results from multiple contract constant function calls.

This reduces the number of separate JSON RPC requests that need to be sent
(especially useful if using remote nodes like Infura), while also providing the
guarantee that all values returned are from the same block (like an atomic read)
and returning the block number the values are from (giving them important
context so that results from old blocks can be ignored if they're from an
out-of-date node).

- [`Multicall`](./src/Multicall.sol): **This is the recommended version**. It's ABI is backwards compatible with Multicall and Multicall2, but it's cheaper to use (so you can fit more calls into a single request), and it adds an `aggregate3` method so you can specify whether calls are allowed to fail on a per-call basis. Additionally, it's deployed on every network at the same address.

These contracts can also be used to batch on-chain transactions.
If using them for this purpose, be aware these contracts are unaudited so use them at your own risk.

## Development

This repo uses [Foundry](https://github.com/gakonst/foundry) for development and testing
and git submodules for dependency management.

Clone the repo and run `forge install` to install dependencies and `forge test` to run tests.

## Human-Readable ABI

Below is the human-readable ABI.
This can be directly passed into an ethers.js `Contract` or `Interface` constructor.

```typescript
const MULTICALL_ABI = [
  'function aggregate(tuple(address target, bytes callData)[] calls) payable returns (tuple(bool success, bytes returnData)[] returnData)'
];
```
