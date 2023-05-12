/**
 * @notice ethers.js (https://docs.ethers.org/v6/) does not have native Multicall3 support so this
 * example shows how to interact with the contract directly. This example shows how to reverse
 * resolve ENS names for a list of addresses. It uses the `aggregate3` method to support reverting
 * calls. To run the example:
 *   - Install dependencies with `pnpm install`
 *   - Run `pnpm ts-node ethers.ts`
 *
 * You can replace `pnpm` with the node package manager of your choice.
 */
import { Contract, Interface, JsonRpcProvider, namehash } from 'ethers';
import { MULTICALL_ADDRESS, MULTICALL_ABI_ETHERS } from './constants';

// Setup the provider (in viem, this is called a client).
const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL;
if (!MAINNET_RPC_URL) throw new Error('Please set the MAINNET_RPC_URL environment variable.');
const provider = new JsonRpcProvider(MAINNET_RPC_URL);

// Get Multicall contract instance.
const multicall = new Contract(MULTICALL_ADDRESS, MULTICALL_ABI_ETHERS, provider);

// Reverse resolve ENS names for a list of addresses using the `aggregate3` method to support
// reverting calls. The process shown here for reverse resolving ENS names is based on:
//   https://github.com/ethers-io/ethers.js/blob/0802b70a724321f56d4c170e4c8a46b7804dfb48/src.ts/providers/abstract-provider.ts#L976
async function example1() {
  // Define some users.
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
  const nameCalls = resolverAddrs.map((resolverAddr, i) => ({
    target: resolverAddr,
    allowFailure: false, // We allow failure for all calls.
    callData: resolverInterface.encodeFunctionData('name', [nodes[i]]),
  }));

  // Execute those calls.
  // TODO This call fails. It seems to be payload specific though, e.g. if I replace `nameCalls`
  // with `resolverCalls` it works. See https://github.com/ethers-io/ethers.js/issues/3953.
  console.log('nameCalls:', nameCalls);
  const nameResults: Aggregate3Response[] = await multicall.aggregate3.staticCall(nameCalls);

  // Decode the responses.
  const names = nameResults.map(({ success, returnData }, i) => {
    if (!success) throw new Error(`Failed to get name for ${users[i]}`);
    if (returnData === '0x') return users[i]; // If no ENS name, return the address.
    return <string>resolverInterface.decodeFunctionResult('name', returnData)[0];
  });

  console.log('names:', names);
}

example1().catch(console.error);
