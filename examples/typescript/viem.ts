import { createPublicClient, http, parseAbi, formatUnits } from 'viem';
import { mainnet } from 'viem/chains';

const client = createPublicClient({
  chain: mainnet,
  transport: http(process.env.ETH_RPC_URL),
});

// Uniswap V3 constants.
const FEE_TIERS = [100, 500, 3000, 10000];
const UNISWAP_FACTORY = {
  address: '0x1F98431c8aD98523631AE4a59f267346ea31F984',
  abi: parseAbi([
    'function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool)',
  ]),
} as const;

// Tokens addresses.
const DAI_ADDRESS = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const USDC_ADDRESS = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';

async function example1() {
  // The first multicall computes the address of the DAI/USDC pool for each fee tier.
  const poolAddrCalls = FEE_TIERS.map((fee) => {
    return {
      ...UNISWAP_FACTORY,
      functionName: 'getPool',
      args: [DAI_ADDRESS, USDC_ADDRESS, fee],
    } as const;
  });

  // Execute the multicall and get the pool addresses. None of these calls can fail so we set
  // `allowFailure` to false. This results in each return value's type matching the type of the
  // corresponding call, e.g. `0x${string}` for addresses, `bigint` for uint256, etc. If we set
  // `allowFailure` to true then the returns types are of the following shape, using the example of
  // the address return type:
  //   {
  //       error: Error;
  //       result?: undefined;
  //       status: "error";
  //   } | {
  //       error?: undefined;
  //       result: `0x${string}`;
  //       status: "success";
  //   }
  const poolAddresses = await client.multicall({ contracts: poolAddrCalls, allowFailure: false });
  console.log('DAI/USDC Pool Addresses');
  const percentages = FEE_TIERS.map((fee) =>
    (fee / 1e6).toLocaleString(undefined, {
      style: 'percent',
      minimumIntegerDigits: 1,
      minimumFractionDigits: 2,
    })
  );
  percentages.map((percent, i) => console.log(`  ${percent} pool: ${poolAddresses[i]}`));

  // For each pool, let's get the DAI and USDC balances.
  const balanceOfAbi = parseAbi([
    'function balanceOf(address who) external view returns (uint256 balance)',
  ]);
  const DAI = { address: DAI_ADDRESS, abi: balanceOfAbi } as const;
  const USDC = { address: USDC_ADDRESS, abi: balanceOfAbi } as const;

  const balanceCalls = poolAddresses
    .map((poolAddress) => {
      return [
        { ...DAI, functionName: 'balanceOf', args: [poolAddress] } as const,
        { ...USDC, functionName: 'balanceOf', args: [poolAddress] } as const,
      ];
    })
    .flat();

  // Execute the multicall and log the results.
  const balances = await client.multicall({ contracts: balanceCalls, allowFailure: false });

  console.log('DAI/USDC Pool Balances');
  balances.map((balance, i) => {
    const token = i % 2 === 0 ? 'DAI' : 'USDC';
    const decimals = i % 2 === 0 ? 18 : 6;
    const percent = percentages[Math.floor(i / 2)];
    const amount = Number(formatUnits(balance, decimals)).toLocaleString(undefined, {});
    const spacer = ' '.repeat(5 - token.length);
    console.log(`  ${percent} pool ${token} balance:${spacer}${amount}`);
  });
}

example1().catch(console.error);
