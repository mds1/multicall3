// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/// @title Multicall3
/// @notice Aggregate results from multiple read-only function calls
/// @dev Multicall & Multicall2 backwards-compatible
/// @dev Aggregate methods are marked `payable` to save 24 gas per call
/// @author Michael Elliot <mike@makerdao.com>
/// @author Joshua Levine <joshua@makerdao.com>
/// @author Nick Johnson <arachnid@notdot.net>
/// @author Andreas Bigger <andreas@nascent.xyz>
contract Multicall3 {
    struct Call {
        address target;
        bytes callData;
    }

    struct Call3 {
        address target;
        bool allowFailure;
        bytes callData;
    }

    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice Backwards-compatible call aggregation with Multicall
    /// @param calls An array of Call structs
    /// @return blockNumber The block number where the calls were executed
    /// @return returnData An array of bytes containing the responses
    function aggregate(Call[] calldata calls) public payable returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        uint256 length = calls.length;
        returnData = new bytes[](length);
        Call calldata call;
        for (uint256 i = 0; i < length;) {
            bool success;
            call = calls[i];
            (success, returnData[i]) = call.target.call(call.callData);
            require(success, "Multicall3: aggregate failed");
            unchecked { ++i; }
        }
    }

    /// @notice Backwards-compatible with Multicall2
    /// @notice Aggregate calls without requiring success
    /// @param requireSuccess If true, require all calls to succeed
    /// @param calls An array of Call structs
    /// @return returnData An array of Result structs
    function tryAggregate(bool requireSuccess, Call[] calldata calls) public payable returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata call;
        for (uint256 i = 0; i < length;) {
            Result memory result = returnData[i];
            call = calls[i];
            (result.success, result.returnData) = call.target.call(call.callData);
            if (requireSuccess) require(result.success, "Multicall3: tryAggregate failed");
            unchecked { ++i; }
        }
    }

    /// @notice Backwards-compatible with Multicall2
    /// @notice Aggregate calls and allow failures using tryAggregate
    /// @param calls An array of Call structs
    /// @return blockNumber The block number where the calls were executed
    /// @return blockHash The hash of the block where the calls were executed
    /// @return returnData An array of Result structs
    function tryBlockAndAggregate(bool requireSuccess, Call[] calldata calls) public payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
        blockNumber = block.number;
        blockHash = blockhash(block.number);
        returnData = tryAggregate(requireSuccess, calls);
    }

    /// @notice Backwards-compatible with Multicall2
    /// @notice Aggregate calls and allow failures using tryAggregate
    /// @param calls An array of Call structs
    /// @return blockNumber The block number where the calls were executed
    /// @return blockHash The hash of the block where the calls were executed
    /// @return returnData An array of Result structs
    function blockAndAggregate(Call[] calldata calls) public payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
        (blockNumber, blockHash, returnData) = tryBlockAndAggregate(true, calls);
    }

    /// @notice Aggregate calls, ensuring each returns success if required
    /// @param calls An array of Call3 structs
    /// @return blockNumber The block number where the calls were executed
    /// @return blockHash The hash of the block where the calls were executed
    /// @return returnData An array of Result structs
    function aggregate3(Call3[] calldata calls) public payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
        blockNumber = block.number;
        blockHash = blockhash(block.number);
        returnData = new Result[](calls.length);
        uint256 length = calls.length;
        Call3 calldata call;
        for (uint256 i = 0; i < length;) {
            Result memory result = returnData[i];
            call = calls[i];
            (result.success, result.returnData) = call.target.call(call.callData);
            require(call.allowFailure || result.success, "Multicall3: aggregate3 failed");
            unchecked { ++i; }
        }
    }

    /// @notice Aggregate calls with a msg value
    /// @notice Reverts if msg.value is less than the sum of the call values
    /// @param calls An array of Call3Value structs
    /// @return returnData An array of Result structs
    function aggregate3Value(Call3Value[] calldata calls) public payable returns (Result[] memory returnData) {
        uint256 valAccumulator;
        returnData = new Result[](calls.length);
        uint256 length = calls.length;
        Call3Value calldata call;
        for (uint256 i = 0; i < length;) {
            Result memory result = returnData[i];
            call = calls[i];
            valAccumulator += call.value;
            require(msg.value >= valAccumulator, "Multicall3: aggregate3Value failed");
            (result.success, result.returnData) = call.target.call{value: call.value}(call.callData);
            require(call.allowFailure || result.success, "Multicall3: aggregate3Value failed");
            unchecked { ++i; }
        }
    }

    /// @notice Returns the block hash for the given block number
    /// @param blockNumber The block number
    /// @return blockHash The 32 byte block hash
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    /// @notice Returns the block number
    /// @return blockNumber The 32 byte (256 bits) unsigned block number
    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    /// @notice Returns the block coinbase
    /// @return coinbase The 20 byte coinbase address
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    /// @notice Returns the block difficulty
    /// @return difficulty The 32 byte (256 bits) unsigned block difficulty
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }

    /// @notice Returns the block gas limit
    /// @return gaslimit The 32 byte (256 bits) unsigned block gas limit
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    /// @notice Returns the block timestamp
    /// @return timestamp The 32 byte (256 bits) unsigned block timestamp
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    /// @notice Returns the (ETH) balance of a given address
    /// @return balance The 32 byte (256 bits) unsigned balance
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    /// @notice Returns the block hash of the last block
    /// @return blockHash The 32 byte last block hash
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        unchecked {
            blockHash = blockhash(block.number - 1);
        }
    }
}
