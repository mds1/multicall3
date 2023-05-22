# Multicall3 Rust Examples

The Rust Multicall3 example uses [ethers-rs](https://github.com/gakonst/ethers-rs).

ethers-rs has native Multicall3 support which we leverage here.
This example batches various calls to the DAI contract with an ETH balance lookup and coinbase address lookup.
It then formats and prints the results.

Run `cargo run` to run the example.
Documentation and examples for the `ethers-rs` Multicall3 functionality can be found in the `ethers-rs` [docs](https://docs.rs/ethers/2.0.4/ethers/contract/struct.Multicall.html).

See the code and comments in [src/main.rs](./src/main.rs) for more information.
