/**
 * @notice Multicall3 example using ethers.js v6: https://docs.ethers.org/v6/. It has no native Multicall3
 * support, so we use the ABI directly. There are two examples:
 *   - Example 1 shows how to query for ETH and multiple token balances for a user in a single call.
 *     It uses the `aggregate` method, which reverts if any call reverts.
 *   - Example 2 shows how to reverse resolve ENS names for a list of addresses. It uses the
 *    `aggregate3` method to support reverting calls.
 */
import { Contract, Interface, JsonRpcProvider, namehash } from 'ethers';
import { MULTICALL_ADDRESS, MULTICALL_ABI, ERC20_ABI } from './constants';

// ==============================
// ======== Shared Setup ========
// ==============================
// Setup the provider.
const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL;
if (!MAINNET_RPC_URL) throw new Error('Please set the MAINNET_RPC_URL environment variable.');
const provider = new JsonRpcProvider(MAINNET_RPC_URL);

// Get Multicall contract instance.
const multicall = new Contract(MULTICALL_ADDRESS, MULTICALL_ABI, provider);

// ===========================
// ======== Example 1 ========
// ===========================
// Query for ETH and multiple token balances for a user in a single call, using the `aggregate`
// method, which reverts if any call reverts.
async function example1() {
  // Define some data.
  const user = '0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168'; // Uniswap V3 DAI/USDC 0.01% pool.
  const tokens = [
    { name: 'DAI', address: '0x6B175474E89094C44Da98b954EedeAC495271d0F' },
    { name: 'DAI', address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48' },
  ];

  // Setup the calls.
  const tokenBalanceCalls = tokens.map((token) => {
    const tokenInterface = new Interface(ERC20_ABI);
    return {
      target: token.address,
      callData: tokenInterface.encodeFunctionData('balanceOf', [user]),
    };
  });

  const ethBalanceCall = {
    target: MULTICALL_ADDRESS,
    callData: multicall.interface.encodeFunctionData('getEthBalance', [user]),
  };

  const calls = [...tokenBalanceCalls, ethBalanceCall];

  // Execute the calls. Here we use `aggregate`, which reverts if any call
  // reverts. You can also use `tryAggregate` to allow calls to revert, or
  // `aggregate3` to set whether calls should revert on a per-call basis. Note
  // that these methods will have different return types, so you'll need to adjust
  // the code accordingly.

  // Execute the call.
  type AggregateResponse = [bigint /* block number */, string[] /* return data */];
  const [blockNumber, data] = <AggregateResponse>await multicall.aggregate.staticCall(calls);
  console.log(`Data from block ${blockNumber}`);

  // Decode the results.
  data.forEach((callData, i) => {
    // We know the first two calls are the tokens, and the last is ETH.
    if (i < tokens.length) {
      const tokenInterface = new Interface(ERC20_ABI);
      const balance = tokenInterface.decodeFunctionResult('balanceOf', callData)[0];
      console.log(`  ${tokens[i].name} balance: ${balance}`);
    } else {
      const balance = multicall.interface.decodeFunctionResult('getEthBalance', callData)[0];
      console.log(`  ETH balance: ${balance}`);
    }
  });
}

example1().catch(console.error);

// ===========================
// ======== Example 2 ========
// ===========================
// Reverse resolve ENS names for a list of addresses using the `aggregate3` method to support
// reverting calls. The process shown here for reverse resolving ENS names is based on:
//   https://github.com/ethers-io/ethers.js/blob/0802b70a724321f56d4c170e4c8a46b7804dfb48/src.ts/providers/abstract-provider.ts#L976
async function example2() {
  // Define some data.
  const users = [
    '0x8700B87C2A053BDE8Cdc84d5078B4AE47c127FeB',
    '0x9EAB9D856a3a667dc4CD10001D59c679C64756E7',
    '0x78d32460D0a53Ac2678e869Eb6b4f6bA9d2Ef360',
    '0x3B60e31CFC48a9074CD5bEbb26C9EAa77650a43F',
    '0x99FBa19112f221D0B44c9c22241f5e6b2Db715F6',
    '0xE943CA883ef3294E0FC55a1A14591aBeAD1B5927',
    '0x26E3a9c84fdB9b7fE33Dfd5E8D273D016e4e4Fb6',
  ];

  // Setup the contract addresses and interface methods that we'll need.
  const ensRegistryAddr = '0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e';
  const ensRegistryInterface = new Interface(['function resolver(bytes32) view returns (address)']);
  const resolverInterface = new Interface(['function name(bytes32) view returns (string)']);

  // CALL 1: Get the reverse resolver address for each account.
  // For each address, compute it's reverse resolver namehash.
  const nodes = users.map((addr) => namehash(addr.substring(2).toLowerCase() + '.addr.reverse'));

  // Prepare the calls to look up each user's resolver address.
  const resolverCalls = nodes.map((node) => ({
    target: ensRegistryAddr,
    allowFailure: true, // We allow failure for all calls.
    callData: ensRegistryInterface.encodeFunctionData('resolver', [node]),
  }));

  // Execute those calls.
  type Aggregate3Response = { success: boolean; returnData: string };
  const resolverResults: Aggregate3Response[] = await multicall.aggregate3.staticCall(
    resolverCalls
  );

  // Decode the responses.
  const resolverAddrs = resolverResults.map(({ success, returnData }, i) => {
    if (!success) throw new Error(`Failed to get resolver for ${users[i]}`);
    return ensRegistryInterface.decodeFunctionResult('resolver', returnData)[0];
  });

  // CALL 2: Get the name for each account.
  // First we prepare the calls.
  console.log('resolverAddrs:', resolverAddrs);
  const nameCalls = resolverAddrs.map((resolverAddr, i) => ({
    target: resolverAddr,
    allowFailure: true, // We allow failure for all calls.
    callData: resolverInterface.encodeFunctionData('name', [nodes[i]]),
  }));

  // Execute those calls.
  console.log('nameCalls:', nameCalls);
  const nameResults: Aggregate3Response[] = await multicall.aggregate3.staticCall(nameCalls);

  // // Decode the responses.
  // const names = nameResults.map(({ success, returnData }, i) => {
  //   if (!success) throw new Error(`Failed to get name for ${users[i]}`);
  //   if (returnData === '0x') return users[i]; // If no ENS name, return the address.
  //   return <string>resolverInterface.decodeFunctionResult('name', returnData)[0];
  // });

  // console.log('names:', names);
}

example2().catch(console.error);
