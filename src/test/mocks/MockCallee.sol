pragma solidity 0.8.17;

contract MockCallee {
  error Unsuccessful();

  function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
    blockHash = blockhash(blockNumber);
  }

  function thisMethodReverts() public pure {
    revert Unsuccessful();
  }

  function sendBackValue(address target) public payable {
    (bool ok, ) = target.call{value: msg.value}("");
    if (!ok) revert Unsuccessful();
  }
}
