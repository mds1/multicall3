// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Multicall3} from "../Multicall3.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {MockCallee} from "./mocks/MockCallee.sol";

contract Multicall3Test is DSTestPlus {
  Multicall3 multicall;
  MockCallee callee;

  /// @notice Setups up the testing suite
  function setUp() public {
    multicall = new Multicall3();
    callee = new MockCallee();
  }

  // /// >>>>>>>>>>>>>>>>>>>>  AGGREGATION TESTS  <<<<<<<<<<<<<<<<<<<< ///

  // function testAggregation() public {
  //   // Test successful call
  //   Multicall.Call[] memory calls = new Multicall.Call[](1);
  //   calls[0] = Multicall.Call(
  //       address(callee),
  //       abi.encodeWithSignature("getBlockHash(uint256)", block.number),
  //       false
  //   );
  //   (
  //       uint256 blockNumber,
  //       bytes32 blockHash,
  //       bytes[] memory returnData
  //   ) = multicall.aggregate(calls);
  //   assert(blockNumber == block.number);
  //   assert(blockHash == blockhash(block.number));
  //   assert(keccak256(returnData[0]) == keccak256(abi.encodePacked(blockhash(block.number))));
  // }

  // function testGracefulAggregation() public {
  //   // Test unexpected revert
  //   Multicall.Call[] memory calls = new Multicall.Call[](2);
  //   calls[0] = Multicall.Call(
  //       address(callee),
  //       abi.encodeWithSignature("getBlockHash(uint256)", block.number),
  //       false
  //   );
  //   calls[1] = Multicall.Call(
  //       address(callee),
  //       abi.encodeWithSignature("thisMethodReverts()"),
  //       false
  //   );
  //   (
  //       uint256 blockNumber,
  //       bytes32 blockHash,
  //       bytes[] memory returnData
  //   ) = multicall.aggregate(calls);
  // }

  // function testUnsuccessulAggregation() public {
  //   // Test unexpected revert
  //   Multicall.Call[] memory calls = new Multicall.Call[](2);
  //   calls[0] = Multicall.Call(
  //       address(callee),
  //       abi.encodeWithSignature("getBlockHash(uint256)", block.number),
  //       false
  //   );
  //   calls[1] = Multicall.Call(
  //       address(callee),
  //       abi.encodeWithSignature("thisMethodReverts()"),
  //       true
  //   );
  //   vm.expectRevert(abi.encodePacked(bytes4(keccak256("UnsuccessfulCall()"))));
  //   (
  //       uint256 blockNumber,
  //       bytes32 blockHash,
  //       bytes[] memory returnData
  //   ) = multicall.aggregate(calls);
  // }

  // /// >>>>>>>>>>>>>>>>>>>>>>  HELPER TESTS  <<<<<<<<<<<<<<<<<<<<<<< ///

  // function testGetBlockHash(uint256 blockNumber) public {
  //   assert(blockhash(blockNumber) == multicall.getBlockHash(blockNumber));
  // }

  // function testGetBlockNumber() public {
  //   assert(block.number == multicall.getBlockNumber());
  // }

  // function testGetCurrentBlockCoinbase() public {
  //   assert(block.coinbase == multicall.getCurrentBlockCoinbase());
  // }

  // function testGetCurrentBlockDifficulty() public {
  //   assert(block.difficulty == multicall.getCurrentBlockDifficulty());
  // }

  // function testGetCurrentBlockGasLimit() public {
  //   assert(block.gaslimit == multicall.getCurrentBlockGasLimit());
  // }

  // function testGetCurrentBlockTimestamp() public {
  //   assert(block.timestamp == multicall.getCurrentBlockTimestamp());
  // }

  // function testGetEthBalance(address addr) public {
  //   assert(addr.balance == multicall.getEthBalance(addr));
  // }

  // function testGetLastBlockHash() public {
  //   // Prevent arithmetic underflow on the genesis block
  //   if(block.number == 0) return;
  //   assert(blockhash(block.number - 1) == multicall.getLastBlockHash());
  // }
}
