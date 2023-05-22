/// Multicall3 example using ethers-rs: https://github.com/gakonst/ethers-rs
///
/// ethers-rs has native Multicall3 support which we leverage here. This example batches various
/// calls to the DAI contract with an ETH balance lookup and coinbase address lookup. It then
/// formats and prints the results.
///
/// Run `cargo run` to run the example. Documentation and examples for the `ethers-rs` Multicall3
/// functionality can be found in the `ethers-rs` docs: https://docs.rs/ethers/2.0.4/ethers/contract/struct.Multicall.html
use ethers::{
    abi::Abi,
    contract::{Contract, Multicall},
    providers::{Http, Provider},
    types::{Address, U256},
    utils::format_units,
};
use serde_json;
use std::{convert::TryFrom, env, error::Error, str::FromStr, sync::Arc};

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    // Create provider.
    let provider = Arc::new(Provider::<Http>::try_from(env::var("MAINNET_RPC_URL")?)?);

    // Define the contracts we want to call. Here we just inline the ABI but you can also load it
    // from a file.
    let dai_address = Address::from_str("0x6B175474E89094C44Da98b954EedeAC495271d0F")?;
    let dai_abi: Abi = serde_json::from_str(
        r#"[{"inputs":[{"internalType":"uint256","name":"chainId_","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"src","type":"address"},{"indexed":true,"internalType":"address","name":"guy","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":true,"inputs":[{"indexed":true,"internalType":"bytes4","name":"sig","type":"bytes4"},{"indexed":true,"internalType":"address","name":"usr","type":"address"},{"indexed":true,"internalType":"bytes32","name":"arg1","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"arg2","type":"bytes32"},{"indexed":false,"internalType":"bytes","name":"data","type":"bytes"}],"name":"LogNote","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"src","type":"address"},{"indexed":true,"internalType":"address","name":"dst","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Transfer","type":"event"},{"constant":true,"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"burn","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"guy","type":"address"}],"name":"deny","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"mint","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"src","type":"address"},{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"move","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"holder","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"expiry","type":"uint256"},{"internalType":"bool","name":"allowed","type":"bool"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"pull","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"push","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"guy","type":"address"}],"name":"rely","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"src","type":"address"},{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"wards","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}]"#,
    )?;
    let dai = Contract::<Provider<Http>>::new(dai_address, dai_abi, provider.clone());

    // Create a multicall instance. It defaults to using Multicall3, and we use `none` since our
    // network has a known Multicall3 address.
    let mut multicall = Multicall::<Provider<Http>>::new(provider, None).await?;

    // Add the calls we want to query. We pass `false` to `add_call` to indicate the call is not
    // allowed to revert.
    let vitalik = Address::from_str("0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")?;
    multicall
        .add_call(multicall.contract.method::<_, Address>("getCurrentBlockCoinbase", ())?, false)
        .add_call(dai.method::<_, String>("symbol", ())?, false)
        .add_call(dai.method::<_, u8>("decimals", ())?, false)
        .add_call(dai.method::<_, U256>("balanceOf", vitalik)?, false)
        .add_get_eth_balance(vitalik, false);

    // Wait for the response of the multicall and format the results. Because we have a fixed list
    // of calls defined above, we know exactly what the response types will be and therefore we
    // can explicitly define the types in the `response` tuple as shown below. If the list of calls
    // was generated dynamically, e.g. in a for loop, then we would not know these types at compile
    // time, so instead we'd have to iterate over the responses and match on the `Token` type of
    // each element in the response.
    let response: (Address, String, u8, U256, U256) = multicall.call().await?;
    let dai_balance = format_units(response.3, response.2 as usize)?;
    let eth_balance = format_units(response.4, "ether")?;

    // Print results, aligning the data.
    let label1 = "Coinbase:";
    let label2 = format!("Vitalik's {} balance:", response.1);
    let label3 = "Vitalik's ETH balance:";
    let width = label1.len().max(label2.len()).max(label3.len());
    println!("{:width$} {:?}", label1, response.0);
    println!("{:width$} {}", label2, dai_balance);
    println!("{:width$} {}", label3, eth_balance);

    Ok(())
}
