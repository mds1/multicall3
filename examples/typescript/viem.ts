import { createPublicClient, http, parseAbi } from 'viem';
import { mainnet } from 'viem/chains';
import { MULTICALL_CONTRACT } from './constants';

const client = createPublicClient({
  chain: mainnet,
  transport: http(),
});

// Uniswap V3 constants.
const UNISWAP_FACTORY = {
  address: '0x1F98431c8aD98523631AE4a59f267346ea31F984',
  abi: parseAbi([
    'function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool)',
  ]),
} as const;

const FEE_TIERS = [100, 500, 3000, 10000];

// Tokens.
const DAI_ADDRESS = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const USDC_ADDRESS = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';

async function example1() {
  // The first multicall computes the address of the DAI/USDC pool for each fee tier.
  const calls = FEE_TIERS.map((fee) => {
    return {
      ...UNISWAP_FACTORY,
      functionName: 'getPool',
      args: [DAI_ADDRESS, USDC_ADDRESS, fee],
    } as const;
  });

  // Execute the multicall and get the results, where e.g. `ft100` is the address of the DAI/USDC
  // pool for the 0.01% fee tier.
  // NOTE Type inference does not work here.
  const [ft100, ft500, ft3000, ft10000] = await client.multicall({ contracts: calls });
  console.log('ft100:  ', ft100.result);
  console.log('ft500:  ', ft500.result);
  console.log('ft3000: ', ft3000.result);
  console.log('ft10000:', ft10000.result);

  // ------------- other stuff --------

  // NOTE Why is the type of blockNumber `bigint | `0x${string}` | undefined` and not `bigint`?
  // If I do `const blockNumber = await client.readContract({ ...MULTICALL_CONTRACT, functionName: 'getBlockNumber' });`
  // then the type is `bigint`, so not sure why the multicall version can't narrow the type further.
  const [blockNumber, currentBlockCoinbase] = await client.multicall({
    contracts: [
      {
        ...MULTICALL_CONTRACT,
        functionName: 'getBlockNumber',
      },
      {
        ...MULTICALL_CONTRACT,
        functionName: 'getCurrentBlockCoinbase',
      },
    ],
  });

  console.log([
    `Contract Address: ${MULTICALL_CONTRACT.address}`,
    `Block number: ${blockNumber.result}`,
    `Coinbase: ${currentBlockCoinbase.result}`,
  ]);

  // NOTE Type inference works fine here, it says blockNumber2 is `bigint`.
  const blockNumber2 = await client.readContract({
    ...MULTICALL_CONTRACT,
    functionName: 'getBlockNumber',
  });
}

example1().catch(console.error);
