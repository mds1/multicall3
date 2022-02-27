// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Multicall} from "../Multicall.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {MockCallee} from "./mocks/MockCallee.sol";

contract MulticallTest is DSTestPlus {
  Multicall multicall;
  MockCallee callee;

  /// @notice Setups up the testing suite
  function setUp() public {
    multicall = new Multicall();
    callee = new MockCallee();
  }

  /// >>>>>>>>>>>>>>>>>>>>  AGGREGATION TESTS  <<<<<<<<<<<<<<<<<<<< ///

  function testAggregation() public {
    // Test successful call
    Multicall.Call[] memory calls = new Multicall.Call[](1);
    calls[0] = Multicall.Call(
        address(callee),
        abi.encodeWithSignature("getBlockHash(uint256)", block.number)
    );
    (
        uint256 blockNumber,
        bytes[] memory returnData
    ) = multicall.aggregate(calls);
    assert(blockNumber == block.number);
    assert(keccak256(returnData[0]) == keccak256(abi.encodePacked(blockhash(block.number))));
  }

  function testUnsuccessulAggregation() public {
    // Test unexpected revert
    Multicall.Call[] memory calls = new Multicall.Call[](2);
    calls[0] = Multicall.Call(
        address(callee),
        abi.encodeWithSignature("getBlockHash(uint256)", block.number)
    );
    calls[1] = Multicall.Call(
        address(callee),
        abi.encodeWithSignature("thisMethodReverts()")
    );
    vm.expectRevert(bytes(""));
    (
        uint256 blockNumber,
        bytes[] memory returnData
    ) = multicall.aggregate(calls);
  }

  /// >>>>>>>>>>>>>>>>>>>>>>  HELPER TESTS  <<<<<<<<<<<<<<<<<<<<<<< ///

  function testGetEthBalance(address addr) public {
    assert(addr.balance == multicall.getEthBalance(addr));
  }

  function testGetBlockHash(uint256 blockNumber) public {
    assert(blockhash(blockNumber) == multicall.getBlockHash(blockNumber));
  }

  function testGetLastBlockHash() public {
    // Prevent arithmetic underflow on the genesis block
    if(block.number == 0) return;
    assert(blockhash(block.number - 1) == multicall.getLastBlockHash());
  }

  function testGetCurrentBlockTimestamp() public {
    assert(block.timestamp == multicall.getCurrentBlockTimestamp());
  }

  function testGetCurrentBlockDifficulty() public {
    assert(block.difficulty == multicall.getCurrentBlockDifficulty());
  }

  function testGetCurrentBlockGasLimit() public {
    assert(block.gaslimit == multicall.getCurrentBlockGasLimit());
  }

  function testGetCurrentBlockCoinbase() public {
    assert(block.coinbase == multicall.getCurrentBlockCoinbase());
  }
}
