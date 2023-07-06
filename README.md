<div align="center">

<h1>Multicall3</h1>

<a href="">![tests](https://github.com/mds1/multicall/actions/workflows/tests.yml/badge.svg)</a>
<a href="">![coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen)</a>
<a href="">![license](https://img.shields.io/github/license/mds1/multicall)</a>

</div>

[`Multicall3`](./src/Multicall3.sol) is deployed on over 70+ chains at `0xcA11bde05977b3631167028862bE2a173976CA11`.
The full list of deployed chains along with the Multicall3 ABI can be found at https://multicall3.com.
The ABI is provided in various formats, and can be copied to your clipboard or downloaded to a file.

Multicall3 is the primary contract in this repository, and **is recommended for all use cases**[^1].

- [Usage](#usage)
  - [Batch Contract Reads](#batch-contract-reads)
  - [Batch Contract Writes](#batch-contract-writes)
- [Deployments and ABI](#deployments-and-abi)
- [Security](#security)
- [Development](#development)
- [Gas Golfing Techniques](#gas-golfing-tricks-and-optimizations)

## Usage

Multicall3 has two main use cases:

- Aggregate results from multiple contract reads into a single JSON-RPC request.
- Execute multiple state-changing calls in a single transaction.

Because it can be used for both use cases, no methods in this contract are `view`, and all can mutate state and are `payable`.

### Batch Contract Reads

This is the most common use case for executing a multicall.
This allows a single `eth_call` JSON RPC request to return the results of multiple contract function calls.
This has many benefits, because it:

- Reduces the number of separate JSON RPC requests that need to be sent, which is especially useful if using remote nodes like Infura. This (1) reduces RPC usage and therefore costs, and (2) reduces the number of round trips between the client and the node, which can significantly improve performance.
- Guarantees that all values returned are from the same block.
- Enables block number or timestamp to be returned with the read data, to help detect stale data.

Many libraries and tools such as [ethers-rs](https://github.com/gakonst/ethers-rs), [viem](https://viem.sh/), and [ape](https://apeworx.io/) have native Multicall3 integration.
To learn how to use Multicall3 with these tools, check out this repo's [examples](./examples) and read the documentation for the tool you're using to learn more.

When directly interacting with the contract to batch calls, the `aggregate3` method is likely what you'll want to use.
It takes an array of `Call3` structs, and returns an array of `Result` structs:

```solidity
struct Call3 {
    // Target contract to call.
    address target;
    // If false, the entire call will revert if the call fails.
    bool allowFailure;
    // Data to call on the target contract.
    bytes callData;
}

struct Result {
    // True if the call succeeded, false otherwise.
    bool success;
    // Return data if the call succeeded, or revert data if the call reverted.
    bytes returnData;
}

/// @notice Aggregate calls, ensuring each returns success if required
/// @param calls An array of Call3 structs
/// @return returnData An array of Result structs
function aggregate3(Call3[] calldata calls) public payable returns (Result[] memory returnData);
```

To obtain the block number or timestamp of the block the calls were executed in with your return data, simply add a call where the `target` is the `Multicall3` contract itself, and the `callData` is the [`getBlockNumber`](./src/Multicall3.sol#L170) or [`getCurrentBlockTimestamp`](./src/Multicall3.sol#L190) method.

There are a number of other methods to return block properties, including:

- [`getBlockHash`](./src/Multicall3.sol#L165): Returns the block hash for the given block number.
- [`getBlockNumber`](./src/Multicall3.sol#L170): Returns the current block's number.
- [`getCurrentBlockCoinbase`](./src/Multicall3.sol#L175): Returns the current block's coinbase.
- [`getCurrentBlockDifficulty`](./src/Multicall3.sol#L180): Returns the current block's difficulty for Proof-of-Work chains or the latest RANDAO value for Proof-of-Stake chains. See [EIP-4399](https://eips.ethereum.org/EIPS/eip-4399) to learn more about this.
- [`getCurrentBlockGasLimit`](./src/Multicall3.sol#L185): Returns the current block's gas limit.
- [`getCurrentBlockTimestamp`](./src/Multicall3.sol#L190): Returns the current block's timestamp.
- [`getEthBalance`](./src/Multicall3.sol#L195): Returns the ETH (or native token) balance of the given address.
- [`getLastBlockHash`](./src/Multicall3.sol#L200): Returns the block hash of the previous block.
- [`getBasefee`](./src/Multicall3.sol#L208): Returns the base fee of the given block. This will revert if the BASEFEE opcode is not supported on the given chain. See [EIP-1599](https://eips.ethereum.org/EIPS/eip-1559) to learn more about this.
- [`getChainId`](./src/Multicall3.sol#L213): Returns the chain ID.

If you need to send less calldata as part of your multicall and can tolerate less granularity of specifying which calls fail, you can check out the other aggregation methods:

- [`aggregate3Value`](./src/Multicall3.sol#L129): Similar to `aggregate3`, but also lets you send values with calls.
- [`aggregate`](./src/Multicall3.sol#L41): Returns a tuple of `(uint256 blockNumber, bytes[] returnData)` and reverts if any call fails.
- [`blockAndAggregate`](./src/Multicall3.sol#L91): Similar to `aggregate`, but also returns the block number and block hash.
- [`tryAggregate`](./src/Multicall3.sol#L60): Takes a `bool` value indicating whether success is required for all calls, and returns a tuple of `(bool success, bytes[] returnData)[]`.
- [`tryBlockAndAggregate`](./src/Multicall3.sol#L79): Similar to `tryAggregate`, but also returns the block number and block hash.

_Note that the above tuples are represented as structs in the code, but are shown above as tuples for brevity._

### Batch Contract Writes

_If using Multicall3 for this purpose, be aware it is unaudited, so use at your own risk._
_However, because it is a stateless contract, it should be safe when used correctly—**it should never hold your funds after a transaction ends, and you should never approve Multicall3 to spend your tokens**_.

Multicall3 can also be used to batch on-chain transactions using the methods described in the [Batch Contract Reads](#batch-contract-reads) section.

When using Multicall3 for this purpose, there are **two important details you MUST understand**.

1. How `msg.sender` behaves when calling vs. delegatecalling to a contract.
2. The risks of using `msg.value` in a multicall.

Before explaining both of these, let's first cover some background on how the Ethereum Virtual Machine (EVM) works.

There are two types of accounts in Ethereum: Externally Owned Accounts (EOAs) and Contract Accounts.
EOAs are controlled by private keys, and Contract Accounts are controlled by code.

When an EOA calls a contract, the `msg.sender` value during execution of the call provides the address of that EOA. This is also true if the call was executed by a contract.
The word "call" here specifically refers to the [`CALL`](https://www.evm.codes/#f1?fork=shanghai) opcode.
Whenever a CALL is executed, the _context_ changes.
New context means storage operations will be performed on the called contract, there is a new value (i.e. `msg.value`), and a new caller (i.e. `msg.sender`).

The EVM also supports the [`DELEGATECALL`](https://www.evm.codes/#f4) opcode, which is similar to `CALL`, but different in a very important way: it _does not_ change the context of the call.
This means the contract being delegatecalled will see the same `msg.sender`, the same `msg.value`, and operate on the same storage as the calling contract. This is very powerful, but can also be dangerous.

It's important to note that you cannot delegatecall from an EOA—an EOA can only call a contract, not delegatecall it.

Now that we understand the difference between `CALL` and `DELEGATECALL`, let's see how this applies to `msg.sender` and `msg.value` concerns.
We know that we can either `CALL` or `DELEGATECALL` to a contract, and that `msg.sender` will be different depending on which opcode we use.

Because you cannot delegatecall from an EOA, this significantly reduces the benefit of calling Multicall3 from an EOA—any calls the Multicall3 executes will have the MultiCall3 address as the `msg.sender`.
**This means you should only call Multicall3 from an EOA if the `msg.sender` does not matter.**

If you are using a contract wallet or executing a call to Multicall3 from another contract, you can either CALL or DELEGATECALL.
Calls will behave the same as described above for the EOA case, and delegatecalls will preserve the context.
This means if you delegatecall to Multicall3 from a contract, the `msg.sender` of the calls executed by Multicall3 will be that contract.
This can be very useful, and is how the Gnosis Safe [Transaction Builder](https://help.safe.global/en/articles/40841-transaction-builder) works to batch calls from a Safe.

Similarly, because `msg.value` does not change with a delegatecall, you must be careful relying on `msg.value` within a multicall.
To learn more about this, see [here](https://github.com/runtimeverification/verified-smart-contracts/wiki/List-of-Security-Vulnerabilities#payable-multicall) and [here](https://samczsun.com/two-rights-might-make-a-wrong/).

## Deployments and ABI

Multicall3 is deployed on over 70 chains at `0xcA11bde05977b3631167028862bE2a173976CA11`[^2].
A sortable, searchable list of all chains it's deployed on can be found at https://multicall3.com/deployments.
To request a Multicall3 deployment to a new chain, please [open an issue](https://github.com/mds1/multicall/issues/new?assignees=mds1&labels=Deployment+Request&projects=&template=deployment_request.yml).
You can speed up the new deploy by sending funds to cover the deploy cost to the deployer account: `0x05f32B3cC3888453ff71B01135B34FF8e41263F2`

The ABI can be found on https://multicall3.com/abi, where it can be downloaded or copied to the clipboard in various formats, including:

- Solidity interface.
- JSON ABI, prettified.
- JSON ABI, minified.
- ethers.js human readable ABI.
- viem human readable ABI.

Alternatively, you can:

- Download the ABI from the [releases](https://github.com/mds1/multicall/releases) page.
- Copy the ABI from [Etherscan](https://etherscan.io/address/0xcA11bde05977b3631167028862bE2a173976CA11#code).
- Install [Foundry](https://github.com/gakonst/foundry/) and run `cast interface 0xcA11bde05977b3631167028862bE2a173976CA11`.

## Security

**This contract is unaudited.**

For on-chain transactions:

- Ensure it never holds your funds after a transaction ends. If it does hold funds, anyone can steal them.
- Never approve Multicall3 to spend your tokens. If you do, anyone can steal your tokens.
- Be sure you understand CALL vs. DELEGATECALL behavior depending on your use case. See the [Batch Contract Writes](#batch-contract-writes) section for more details.

For off-chain reads the worst case scenario is you get back incorrect data, but this should not occur for properly formatted calls.

## Development

This repo uses [Foundry](https://github.com/gakonst/foundry) for development and testing
and git submodules for dependency management.

Clone the repo and run `forge test` to run tests.
Forge will automatically install any missing dependencies.

The repo for https://multicall3.com can be found [here](https://github.com/mds1/multicall3-frontend).

## Gas Golfing Tricks and Optimizations

Below is a list of some of the optimizations used by Multicall3's `aggregate3` and `aggregate3Value` methods[^3]:

- In `for` loops, array length is cached to avoid reading the length on each loop iteration.
- In `for` loops, the counter is incremented within an `unchecked` block.
- In `for` loops, the counter is incremented with the prefix increment (`++i`) instead of a postfix increment (`i++`).
- All revert strings fit within a single 32 byte slot.
- Function parameters use `calldata` instead of `memory`.
- Instead of requiring `call.allowFailure || result.success`, we use assembly's `or()` instruction to [avoid](https://twitter.com/transmissions11/status/1501645922266091524) a `JUMPI` and `iszero()` since it's cheaper to evaluate both conditions.
- Methods are given a `payable` modifier which removes a check that `msg.value == 0` when calling a method.
- Calldata and memory pointers are used to cache values so they are not read multiple times within a loop.
- No block data (e.g. block number, hash, or timestamp) is returned by default, and is instead left up to the caller.
- The value accumulator in `aggregate3Value` is within an `unchecked` block.

Read more about Solidity gas optimization tips:

- [Generic writeup about common gas optimizations, etc.](https://gist.github.com/hrkrshnn/ee8fabd532058307229d65dcd5836ddc) by [Harikrishnan Mulackal](https://twitter.com/_hrkrshnn)
- [Yul (and Some Solidity) Optimizations and Tricks](https://hackmd.io/@gn56kcRBQc6mOi7LCgbv1g/rJez8O8st) by [ControlCplusControlV](https://twitter.com/controlcthenv)

[^1]: [`Multicall`](./src/Multicall.sol) is the original contract, and [`Multicall2`](./src/Multicall2.sol) added support for handling failed calls in a multicall. [`Multicall3`](./src/Multicall3.sol) is recommended over these because it's backwards-compatible with both, cheaper to use, adds new methods, and is deployed on more chains. You can read more about the original contracts and their deployments in the [makerdao/multicall](https://github.com/makerdao/multicall) repo.
[^2]: There are a few unofficial deployments at other addresses for chains that compute addresses differently, which can also be found at
[^3]: Some of these tricks are outdated with newer Solidity versions and via-ir. Be sure to benchmark your code before assuming the changes are guaranteed to reduce gas usage.
