pragma solidity 0.8.17;

import {Multicall} from "../Multicall.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {MockCallee} from "./mocks/MockCallee.sol";

contract MulticallTest is DSTestPlus {
  Multicall multicall;
  MockCallee callee;

  function setUp() public {
    multicall = new Multicall();
    callee = new MockCallee();
  }

  function testSuccessfulAggregation() public {
    Multicall.Call[] memory calls = new Multicall.Call[](1);
    calls[0] = Multicall.Call(address(callee), abi.encodeWithSignature("getBlockHash(uint256)", block.number));
    (Multicall.Result[] memory returnData) = multicall.aggregate(calls);
    assertTrue(returnData[0].success);
    assertEq(keccak256(returnData[0].returnData), keccak256(abi.encodePacked(blockhash(block.number))));
  }

  function testAggregationWithReversal() public {
    Multicall.Call[] memory calls = new Multicall.Call[](2);
    calls[0] = Multicall.Call(address(callee), abi.encodeWithSignature("getBlockHash(uint256)", block.number));
    calls[1] = Multicall.Call(address(callee), abi.encodeWithSignature("thisMethodReverts()"));
    vm.expectRevert(bytes("Multicall: call failed"));
    multicall.aggregate(calls);
  }
}
