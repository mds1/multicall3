# Multicall3 Examples

Each folder in this directory contains a self-contained example of how to use Multicall3 for the given language or framework.
All examples assume an environment variable called `MAINNET_RPC_URL` is set to a valid Ethereum mainnet RPC URL.

The examples are intentionally _not_ identical for each language, to show a wider set of use cases (but there are similarities and overlap).
For example, the TypeScript `ethers.js` examples shows ENS resolution using multicall, whereas the Rust `ethers-rs` example fetches token and ETH balances for a given address.
As a result, you may find it useful to look at the examples for multiple languages even if you only plan to use one of them.
All examples are well commented to try making them understandable even if you are not familiar with the language.

The examples are also not intended to be production-ready code, but rather to show how to use Multicall3 in a simple way.
