pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Multicall is Ownable {
    struct Call {
        address target;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function aggregate(Call[] calldata calls) public payable onlyOwner returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata call;
        for (uint256 i = 0; i < length;) {
            Result memory result = returnData[i];
            call = calls[i];
            (result.success, result.returnData) = call.target.call(call.callData);
            require(result.success, "Multicall: call failed");
            unchecked { ++i; }
        }
    }
}
