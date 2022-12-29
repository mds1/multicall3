pragma solidity 0.8.17;

import {DSTest} from "@ds/test.sol";
import {stdCheats} from "@std/stdlib.sol";
import {Vm} from "@std/Vm.sol";

contract DSTestPlus is DSTest, stdCheats {
    Vm public constant vm = Vm(HEVM_ADDRESS);
}