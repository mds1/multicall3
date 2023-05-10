// The viem and ethers.js human-readable ABI's are different. First we have `MULTICALL_ABI` which is
// the viem-compatible version, then `MULTICALL_ABI_ETHERS` which is the ethers.js-compatible
// version. We could have provided the standard JSON ABI instead and used it with both ethers and
// viem, but human-readable ABI's are much more readable.

export const MULTICALL_ADDRESS = '0xcA11bde05977b3631167028862bE2a173976CA11';

// Viem.
import { parseAbi } from 'viem';
export const MULTICALL_ABI = [
  // https://github.com/mds1/multicall
  'struct Call { address target; bytes callData; }',
  'struct Call3 { address target; bool allowFailure; bytes callData; }',
  'struct Call3Value { address target; bool allowFailure; uint256 value; bytes callData; }',
  'struct Result { bool success; bytes returnData; }',
  'function aggregate(Call[] calldata calls) public payable returns (uint256 blockNumber, bytes[] memory returnData)',
  'function tryAggregate(bool requireSuccess, Call[] calldata calls) public payable returns (Result[] memory returnData)',
  'function tryBlockAndAggregate(bool requireSuccess, Call[] calldata calls) public payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData)',
  'function blockAndAggregate(Call[] calldata calls) public payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData)',
  'function aggregate3(Call3[] calldata calls) public payable returns (Result[] memory returnData)',
  'function aggregate3Value(Call3Value[] calldata calls) public payable returns (Result[] memory returnData)',
  'function getBasefee() view returns (uint256 basefee)',
  'function getBlockHash(uint256 blockNumber) view returns (bytes32 blockHash)',
  'function getBlockNumber() view returns (uint256 blockNumber)',
  'function getChainId() view returns (uint256 chainid)',
  'function getCurrentBlockCoinbase() view returns (address coinbase)',
  'function getCurrentBlockDifficulty() view returns (uint256 difficulty)',
  'function getCurrentBlockGasLimit() view returns (uint256 gaslimit)',
  'function getCurrentBlockTimestamp() view returns (uint256 timestamp)',
  'function getEthBalance(address addr) view returns (uint256 balance)',
  'function getLastBlockHash() view returns (bytes32 blockHash)',
] as const;

export const MULTICALL_CONTRACT = {
  address: MULTICALL_ADDRESS,
  abi: parseAbi(MULTICALL_ABI),
} as const;

// Ethers
export const MULTICALL_ABI_ETHERS = [
  // https://github.com/mds1/multicall
  'function aggregate(tuple(address target, bytes callData)[] calls) payable returns (uint256 blockNumber, bytes[] returnData)',
  'function aggregate3(tuple(address target, bool allowFailure, bytes callData)[] calls) payable returns (tuple(bool success, bytes returnData)[] returnData)',
  'function aggregate3Value(tuple(address target, bool allowFailure, uint256 value, bytes callData)[] calls) payable returns (tuple(bool success, bytes returnData)[] returnData)',
  'function blockAndAggregate(tuple(address target, bytes callData)[] calls) payable returns (uint256 blockNumber, bytes32 blockHash, tuple(bool success, bytes returnData)[] returnData)',
  'function getBasefee() view returns (uint256 basefee)',
  'function getBlockHash(uint256 blockNumber) view returns (bytes32 blockHash)',
  'function getBlockNumber() view returns (uint256 blockNumber)',
  'function getChainId() view returns (uint256 chainid)',
  'function getCurrentBlockCoinbase() view returns (address coinbase)',
  'function getCurrentBlockDifficulty() view returns (uint256 difficulty)',
  'function getCurrentBlockGasLimit() view returns (uint256 gaslimit)',
  'function getCurrentBlockTimestamp() view returns (uint256 timestamp)',
  'function getEthBalance(address addr) view returns (uint256 balance)',
  'function getLastBlockHash() view returns (bytes32 blockHash)',
  'function tryAggregate(bool requireSuccess, tuple(address target, bytes callData)[] calls) payable returns (tuple(bool success, bytes returnData)[] returnData)',
  'function tryBlockAndAggregate(bool requireSuccess, tuple(address target, bytes callData)[] calls) payable returns (uint256 blockNumber, bytes32 blockHash, tuple(bool success, bytes returnData)[] returnData)',
];

export const ERC20_ABI = [
  'event Approval(address indexed owner, address indexed spender, uint256 value)',
  'event UnBlacklisted(address indexed _account)',
  'function allowance(address owner, address spender) view returns (uint256)',
  'function approve(address spender, uint256 value) returns (bool)',
  'function balanceOf(address account) view returns (uint256)',
  'function decimals() view returns (uint8)',
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function totalSupply() view returns (uint256)',
  'function transfer(address to, uint256 value) returns (bool)',
  'function transferFrom(address from, address to, uint256 value) returns (bool)',
] as const;