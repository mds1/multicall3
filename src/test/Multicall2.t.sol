// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Multicall2} from "../Multicall2.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {MockCallee} from "./mocks/MockCallee.sol";

contract Multicall2Test is DSTestPlus {
  Multicall2 multicall;
  MockCallee callee;

  /// @notice Setups up the testing suite
  function setUp() public {
    multicall = new Multicall2();
    callee = new MockCallee();
  }

  /// >>>>>>>>>>>>>>>>>>>>>  AGGREGATE TESTS  <<<<<<<<<<<<<<<<<<<<< ///

  function testAggregation() public {
    // Test successful call
    Multicall2.Call[] memory calls = new Multicall2.Call[](1);
    calls[0] = Multicall2.Call(address(callee), abi.encodeWithSignature("getBlockHash(uint256)", block.number));
    (uint256 blockNumber, bytes[] memory returnData) = multicall.aggregate(calls);
    assert(blockNumber == block.number);
    assert(keccak256(returnData[0]) == keccak256(abi.encodePacked(blockhash(block.number))));
  }

  function testUnsuccessulAggregation() public {
    // Test unexpected revert
    Multicall2.Call[] memory calls = new Multicall2.Call[](2);
    calls[0] = Multicall2.Call(address(callee), abi.encodeWithSignature("getBlockHash(uint256)", block.number));
    calls[1] = Multicall2.Call(address(callee), abi.encodeWithSignature("thisMethodReverts()"));
    vm.expectRevert(bytes("Multicall aggregate: call failed"));
    multicall.aggregate(calls);
  }

  /// >>>>>>>>>>>>>>>>>>>  TRY AGGREGATE TESTS  <<<<<<<<<<<<<<<<<<< ///

  function testTryAggregate() public {
    Multicall2.Call[] memory calls = new Multicall2.Call[](2);
    calls[0] = Multicall2.Call(address(callee), abi.encodeWithSignature("getBlockHash(uint256)", block.number));
    calls[1] = Multicall2.Call(address(callee), abi.encodeWithSignature("thisMethodReverts()"));
    (Multicall2.Result[] memory returnData) = multicall.tryAggregate(false, calls);
    assert(returnData[0].success == true);
    assert(keccak256(returnData[0].returnData) == keccak256(abi.encodePacked(blockhash(block.number))));
    assert(returnData[1].success == false);
  }

  function testTryAggregateUnsuccessful() public {
    Multicall2.Call[] memory calls = new Multicall2.Call[](2);
    calls[0] = Multicall2.Call(address(callee), abi.encodeWithSignature("getBlockHash(uint256)", block.number));
    calls[1] = Multicall2.Call(address(callee), abi.encodeWithSignature("thisMethodReverts()"));
    vm.expectRevert(bytes("Multicall2 aggregate: call failed"));
    multicall.tryAggregate(true, calls);
  }

  /// >>>>>>>>>>>>>>  TRY BLOCK AND AGGREGATE TESTS  <<<<<<<<<<<<<< ///

  function testTryBlockAndAggregate() public {
    Multicall2.Call[] memory calls = new Multicall2.Call[](2);
    calls[0] = Multicall2.Call(address(callee), abi.encodeWithSignature("getBlockHash(uint256)", block.number));
    calls[1] = Multicall2.Call(address(callee), abi.encodeWithSignature("thisMethodReverts()"));
    (uint256 blockNumber, bytes32 blockHash, Multicall2.Result[] memory returnData) = multicall.tryBlockAndAggregate(false, calls);
    assert(blockNumber == block.number);
    assert(blockHash == blockhash(block.number));
    assert(returnData[0].success == true);
    assert(keccak256(returnData[0].returnData) == keccak256(abi.encodePacked(blockhash(block.number))));
    assert(returnData[1].success == false);
  }

  function testTryBlockAndAggregateUnsuccessful() public {
    Multicall2.Call[] memory calls = new Multicall2.Call[](2);
    calls[0] = Multicall2.Call(address(callee), abi.encodeWithSignature("getBlockHash(uint256)", block.number));
    calls[1] = Multicall2.Call(address(callee), abi.encodeWithSignature("thisMethodReverts()"));
    vm.expectRevert(bytes("Multicall2 aggregate: call failed"));
    multicall.tryBlockAndAggregate(true, calls);
  }

  function testBlockAndAggregateUnsuccessful() public {
    Multicall2.Call[] memory calls = new Multicall2.Call[](2);
    calls[0] = Multicall2.Call(address(callee), abi.encodeWithSignature("getBlockHash(uint256)", block.number));
    calls[1] = Multicall2.Call(address(callee), abi.encodeWithSignature("thisMethodReverts()"));
    vm.expectRevert(bytes("Multicall2 aggregate: call failed"));
    multicall.blockAndAggregate(calls);
  }

  /// >>>>>>>>>>>>>>>>>>>>>>  HELPER TESTS  <<<<<<<<<<<<<<<<<<<<<<< ///

  function testGetBlockHash(uint256 blockNumber) public {
    assert(blockhash(blockNumber) == multicall.getBlockHash(blockNumber));
  }

  function testGetBlockNumber() public {
    assert(block.number == multicall.getBlockNumber());
  }

  function testGetCurrentBlockCoinbase() public {
    assert(block.coinbase == multicall.getCurrentBlockCoinbase());
  }

  function testGetCurrentBlockDifficulty() public {
    assert(block.difficulty == multicall.getCurrentBlockDifficulty());
  }

  function testGetCurrentBlockGasLimit() public {
    assert(block.gaslimit == multicall.getCurrentBlockGasLimit());
  }

  function testGetCurrentBlockTimestamp() public {
    assert(block.timestamp == multicall.getCurrentBlockTimestamp());
  }

  function testGetEthBalance(address addr) public {
    assert(addr.balance == multicall.getEthBalance(addr));
  }

  function testGetLastBlockHash() public {
    // Prevent arithmetic underflow on the genesis block
    if (block.number == 0) return;
    assert(blockhash(block.number - 1) == multicall.getLastBlockHash());
  }
}
