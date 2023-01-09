// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

interface IMulticall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] calldata calls)
        external
        returns (uint256 blockNumber, bytes[] memory returnData);

    function getBlockHash(uint256 blockNumber) external view returns (bytes32 blockHash);

    function getCurrentBlockCoinbase() external view returns (address coinbase);

    function getCurrentBlockDifficulty() external view returns (uint256 difficulty);

    function getCurrentBlockGasLimit() external view returns (uint256 gaslimit);

    function getCurrentBlockTimestamp() external view returns (uint256 timestamp);

    function getEthBalance(address addr) external view returns (uint256 balance);
    
    function getLastBlockHash() external view returns (bytes32 blockHash);
}
