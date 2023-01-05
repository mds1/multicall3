// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IMulticall2 {
    struct Call {
        address target;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function aggregate(Call[] memory calls) external returns (uint256 blockNumber, bytes[] memory returnData);

    function blockAndAggregate(Call[] memory calls)
        external
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);

    function getBlockHash(uint256 blockNumber) external view returns (bytes32 blockHash);

    function getBlockNumber() external view returns (uint256 blockNumber);

    function getCurrentBlockCoinbase() external view returns (address coinbase);

    function getCurrentBlockDifficulty() external view returns (uint256 difficulty);

    function getCurrentBlockGasLimit() external view returns (uint256 gaslimit);

    function getCurrentBlockTimestamp() external view returns (uint256 timestamp);

    function getEthBalance(address addr) external view returns (uint256 balance);

    function getLastBlockHash() external view returns (bytes32 blockHash);

    function tryAggregate(bool requireSuccess, Call[] memory calls) external returns (Result[] memory returnData);
    
    function tryBlockAndAggregate(bool requireSuccess, Call[] memory calls)
        external
        returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);
}

