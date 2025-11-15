// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Arithmetic} from "../src/Arithmetic.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        new Arithmetic();

        vm.stopBroadcast();
    }
}