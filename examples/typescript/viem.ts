import { createPublicClient, http } from 'viem';
import { mainnet } from 'viem/chains';
import { MULTICALL_CONTRACT } from './constants';

const client = createPublicClient({
  chain: mainnet,
  transport: http(),
});

async function example1() {
  // TODO Why is the type of blockNumber `bigint | `0x${string}` | undefined` and not `bigint`?
  // If I do `const blockNumber = await client.readContract({ ...MULTICALL_CONTRACT, functionName: 'getBlockNumber' });`
  // then the type is `bigint`, so not sure why the multicall version can't narrow the type further.
  const [blockNumber, currentBlockCoinbase] = (
    await client.multicall({
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
    })
  ).map((v) => v.result);

  console.log([
    `Contract Address: ${MULTICALL_CONTRACT.address}`,
    `Block number: ${blockNumber}`,
    `Coinbase: ${currentBlockCoinbase}`,
  ]);

  const blockNumber2 = await client.readContract({
    ...MULTICALL_CONTRACT,
    functionName: 'getBlockNumber',
  });
}

example1().catch(console.error);
