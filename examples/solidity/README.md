# Multicall3 Solidity Examples

Since this examples folder lives in the Multicall3 repo, the Solidity examples will simply link out to other examples to avoid having a forge project within this forge repo.

For Solidity examples, see:

- The Multicall3 tests themselves, found in [`Multicall3.t.sol`](../../src/test/Multicall3.t.sol). In particular the `testAggregate3` test shows how to decode responses.
- The [`getTokenBalances`](https://github.com/foundry-rs/forge-std/blob/73d44ec7d124e3831bc5f832267889ffb6f9bc3f/src/StdUtils.sol#L143-L171) helper method in [forge-std](https://github.com/foundry-rs/forge-std) and it's [tests](https://github.com/foundry-rs/forge-std/blob/73d44ec7d124e3831bc5f832267889ffb6f9bc3f/test/StdUtils.t.sol#L231-L297).

The Solidity examples are more brief and straightforward than other languages' examples, because using Multicall3 in Solidity is very similar to making other arbitrary external calls and encoding/decoding the results.
