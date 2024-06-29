<div align="center">

<h1>Multicall3</h1>

<a href="">![tests](https://github.com/mds1/multicall/actions/workflows/tests.yml/badge.svg)</a>
<a href="">![coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen)</a>
<a href="">![license](https://img.shields.io/github/license/mds1/multicall)</a>

</div>

> [!IMPORTANT]
> New deployment requests will not be fulfilled until around mid to end July.
> To minimize waiting time until deployment during that time, consider using the
> pre-signed transaction method described in this README. Please read that section
> CAREFULLY before using it to ensure it will work on your chain and not burn the nonce!

[`Multicall3`](./src/Multicall3.sol) is deployed on over 70+ chains at `0xcA11bde05977b3631167028862bE2a173976CA11`.
The full list of deployed chains along with the Multicall3 ABI can be found at https://multicall3.com.
The ABI is provided in various formats, and can be copied to your clipboard or downloaded to a file.

Multicall3 is the primary contract in this repository, and **is recommended for all use cases**[^1].

- [Usage](#usage)
  - [Batch Contract Reads](#batch-contract-reads)
  - [Batch Contract Writes](#batch-contract-writes)
- [Deployments and ABI](#deployments-and-abi)
  - [Existing Deployments](#existing-deployments)
  - [New Deployments](#new-deployments)
  - [Contract Verification](#contract-verification)
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

### Existing Deployments

Multicall3 is deployed on over 100 chains at `0xcA11bde05977b3631167028862bE2a173976CA11`[^2].
A sortable, searchable list of all chains it's deployed on can be found at https://multicall3.com/deployments.

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

### New Deployments

> [!IMPORTANT]
> New deployment requests will not be fulfilled until around mid to end July.
> To minimize waiting time until deployment during that time, consider using the
> pre-signed transaction method described in this README. Please read that section
> CAREFULLY before using it to ensure it will work on your chain and not burn the nonce!

There are two ways to get Multicall3 deployed to a chain:

1. Deploy it yourself using a pre-signed transaction. Details on how to do this are in the below paragraph.
2. Request deployment by [opening an issue](https://github.com/mds1/multicall/issues/new?assignees=mds1&labels=Deployment+Request&projects=&template=deployment_request.yml).
   You can significantly reduce the time to deployment by sending funds to cover the deploy cost to the deployer preparation account: `0x1E91557322053858cf75cFE5b2d030D27cb2cA8D`.
   This account is not the deployer, but is used to hold funds until deployment time. This reduces the risk of using the funds in the deployer account for other purposes to prevent accidentally burning the nonce.

> [!WARNING]
> Before using the signed transaction, you **MUST** make sure the chain's gas metering is equivalent to the EVM's.
>
> The pre-signed transaction has a gas limit of 1,000,000 gas, so if the chain will require more than 1M gas to deploy the transaction will revert and we will be unable to deploy Multicall3 at that address. If that happens, the only way to get Multicall3 at the expected address is for the chain to place the contract there as a predeploy.
>
> If you are unsure how to verify this, you can either use the `eth_estimateGas` RPC method or simply deploy the Multicall3 contract from another account and see how much gas deployment used. EVM chains should require exactly 872,776 gas to deploy Multicall3.
>
> Arbitrum chains are well-known chains that cannot be deployed using the pre-signed transaction. See [this](https://arbiscan.io/tx/0x211f6689adbb0f3fba7392e899d23bde029cef532cbd0ae900920cc09f7d1f32) deployment on Arbitrum One that required a gas limit of 14,345,935 gas—well above the 1,000,000 gas limit of the signed transaction.

It's recommended to test sending the transaction on a local network——such as an anvil instance forked from the chain—to verify it works as expected before deploying to a production network.
You can see an example of a successful deployment using the signed transaction on Base [here](https://basescan.org/tx/0x07471adfe8f4ec553c1199f495be97fc8be8e0626ae307281c22534460184ed1).

After deploying, **please open a PR to update the `deployments.json` file with the new deployment**, this way other users can easily know that it's deployed.

Below is the signed transaction.
It has a gas limit of 1,000,000 gas and a gas price of 100 gwei, so before deploying you'll need to send at least 0.1 ETH to the deployer deployer address (`0x05f32b3cc3888453ff71b01135b34ff8e41263f2`).
It is recommended to send ETH to this account as late as possible to reduce the risk of accidentally burning the nonce.

```text
0xf90f538085174876e800830f42408080b90f00608060405234801561001057600080fd5b50610ee0806100206000396000f3fe6080604052600436106100f35760003560e01c80634d2301cc1161008a578063a8b0574e11610059578063a8b0574e1461025a578063bce38bd714610275578063c3077fa914610288578063ee82ac5e1461029b57600080fd5b80634d2301cc146101ec57806372425d9d1461022157806382ad56cb1461023457806386d516e81461024757600080fd5b80633408e470116100c65780633408e47014610191578063399542e9146101a45780633e64a696146101c657806342cbb15c146101d957600080fd5b80630f28c97d146100f8578063174dea711461011a578063252dba421461013a57806327e86d6e1461015b575b600080fd5b34801561010457600080fd5b50425b6040519081526020015b60405180910390f35b61012d610128366004610a85565b6102ba565b6040516101119190610bbe565b61014d610148366004610a85565b6104ef565b604051610111929190610bd8565b34801561016757600080fd5b50437fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0140610107565b34801561019d57600080fd5b5046610107565b6101b76101b2366004610c60565b610690565b60405161011193929190610cba565b3480156101d257600080fd5b5048610107565b3480156101e557600080fd5b5043610107565b3480156101f857600080fd5b50610107610207366004610ce2565b73ffffffffffffffffffffffffffffffffffffffff163190565b34801561022d57600080fd5b5044610107565b61012d610242366004610a85565b6106ab565b34801561025357600080fd5b5045610107565b34801561026657600080fd5b50604051418152602001610111565b61012d610283366004610c60565b61085a565b6101b7610296366004610a85565b610a1a565b3480156102a757600080fd5b506101076102b6366004610d18565b4090565b60606000828067ffffffffffffffff8111156102d8576102d8610d31565b60405190808252806020026020018201604052801561031e57816020015b6040805180820190915260008152606060208201528152602001906001900390816102f65790505b5092503660005b8281101561047757600085828151811061034157610341610d60565b6020026020010151905087878381811061035d5761035d610d60565b905060200281019061036f9190610d8f565b6040810135958601959093506103886020850185610ce2565b73ffffffffffffffffffffffffffffffffffffffff16816103ac6060870187610dcd565b6040516103ba929190610e32565b60006040518083038185875af1925050503d80600081146103f7576040519150601f19603f3d011682016040523d82523d6000602084013e6103fc565b606091505b50602080850191909152901515808452908501351761046d577f08c379a000000000000000000000000000000000000000000000000000000000600052602060045260176024527f4d756c746963616c6c333a2063616c6c206661696c656400000000000000000060445260846000fd5b5050600101610325565b508234146104e6576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601a60248201527f4d756c746963616c6c333a2076616c7565206d69736d6174636800000000000060448201526064015b60405180910390fd5b50505092915050565b436060828067ffffffffffffffff81111561050c5761050c610d31565b60405190808252806020026020018201604052801561053f57816020015b606081526020019060019003908161052a5790505b5091503660005b8281101561068657600087878381811061056257610562610d60565b90506020028101906105749190610e42565b92506105836020840184610ce2565b73ffffffffffffffffffffffffffffffffffffffff166105a66020850185610dcd565b6040516105b4929190610e32565b6000604051808303816000865af19150503d80600081146105f1576040519150601f19603f3d011682016040523d82523d6000602084013e6105f6565b606091505b5086848151811061060957610609610d60565b602090810291909101015290508061067d576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601760248201527f4d756c746963616c6c333a2063616c6c206661696c656400000000000000000060448201526064016104dd565b50600101610546565b5050509250929050565b43804060606106a086868661085a565b905093509350939050565b6060818067ffffffffffffffff8111156106c7576106c7610d31565b60405190808252806020026020018201604052801561070d57816020015b6040805180820190915260008152606060208201528152602001906001900390816106e55790505b5091503660005b828110156104e657600084828151811061073057610730610d60565b6020026020010151905086868381811061074c5761074c610d60565b905060200281019061075e9190610e76565b925061076d6020840184610ce2565b73ffffffffffffffffffffffffffffffffffffffff166107906040850185610dcd565b60405161079e929190610e32565b6000604051808303816000865af19150503d80600081146107db576040519150601f19603f3d011682016040523d82523d6000602084013e6107e0565b606091505b506020808401919091529015158083529084013517610851577f08c379a000000000000000000000000000000000000000000000000000000000600052602060045260176024527f4d756c746963616c6c333a2063616c6c206661696c656400000000000000000060445260646000fd5b50600101610714565b6060818067ffffffffffffffff81111561087657610876610d31565b6040519080825280602002602001820160405280156108bc57816020015b6040805180820190915260008152606060208201528152602001906001900390816108945790505b5091503660005b82811015610a105760008482815181106108df576108df610d60565b602002602001015190508686838181106108fb576108fb610d60565b905060200281019061090d9190610e42565b925061091c6020840184610ce2565b73ffffffffffffffffffffffffffffffffffffffff1661093f6020850185610dcd565b60405161094d929190610e32565b6000604051808303816000865af19150503d806000811461098a576040519150601f19603f3d011682016040523d82523d6000602084013e61098f565b606091505b506020830152151581528715610a07578051610a07576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601760248201527f4d756c746963616c6c333a2063616c6c206661696c656400000000000000000060448201526064016104dd565b506001016108c3565b5050509392505050565b6000806060610a2b60018686610690565b919790965090945092505050565b60008083601f840112610a4b57600080fd5b50813567ffffffffffffffff811115610a6357600080fd5b6020830191508360208260051b8501011115610a7e57600080fd5b9250929050565b60008060208385031215610a9857600080fd5b823567ffffffffffffffff811115610aaf57600080fd5b610abb85828601610a39565b90969095509350505050565b6000815180845260005b81811015610aed57602081850181015186830182015201610ad1565b81811115610aff576000602083870101525b50601f017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0169290920160200192915050565b600082825180855260208086019550808260051b84010181860160005b84811015610bb1578583037fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe001895281518051151584528401516040858501819052610b9d81860183610ac7565b9a86019a9450505090830190600101610b4f565b5090979650505050505050565b602081526000610bd16020830184610b32565b9392505050565b600060408201848352602060408185015281855180845260608601915060608160051b870101935082870160005b82811015610c52577fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa0888703018452610c40868351610ac7565b95509284019290840190600101610c06565b509398975050505050505050565b600080600060408486031215610c7557600080fd5b83358015158114610c8557600080fd5b9250602084013567ffffffffffffffff811115610ca157600080fd5b610cad86828701610a39565b9497909650939450505050565b838152826020820152606060408201526000610cd96060830184610b32565b95945050505050565b600060208284031215610cf457600080fd5b813573ffffffffffffffffffffffffffffffffffffffff81168114610bd157600080fd5b600060208284031215610d2a57600080fd5b5035919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b600082357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff81833603018112610dc357600080fd5b9190910192915050565b60008083357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe1843603018112610e0257600080fd5b83018035915067ffffffffffffffff821115610e1d57600080fd5b602001915036819003821315610a7e57600080fd5b8183823760009101908152919050565b600082357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc1833603018112610dc357600080fd5b600082357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa1833603018112610dc357600080fdfea2646970667358221220bb2b5c71a328032f97c676ae39a1ec2148d3e5d6f73d95e9b17910152d61f16264736f6c634300080c00331ca0edce47092c0f398cebf3ffc267f05c8e7076e3b89445e0fe50f6332273d4569ba01b0b9d000e19b24c5869b0fc3b22b0d6fa47cd63316875cbbd577d76e6fde086
```

To deploy with [cast](https://book.getfoundry.sh/cast/):

```sh
# `TX` is the signed transaction above.
# `RPC_URL` is the RPC URL of the chain you want to deploy to.
cast publish $TX --rpc-url $RPC_URL
```

### Contract Verification

To verify the code on a block explorer, use the following parameters:

- Paste in the code from [Multicall3.sol](./src/Multicall3.sol)
- Select solidity 0.8.12
- Optimizer enabled with 10000000 runs
- No constructor arguments

## Security

**This contract is unaudited.**

For on-chain transactions using Multicall3, or for contracts inheriting from Multicall3:

- **Ensure it NEVER holds funds after a transaction ends**. Any ETH, tokens, or other funds held by this contract can be stolen. There are bots that monitor for this and they will immediately steal any funds they find.
- Never approve Multicall3 to spend your tokens. If you do, anyone can steal your tokens. There are likely bots that monitor for this as well.
- It is not recommended to inherit from this contract if your contract will hold funds. But if you must, be sure you know what you're doing and protect all state changing methods with an `onlyOwner` modifier or similar so funds cannot be stolen.
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
