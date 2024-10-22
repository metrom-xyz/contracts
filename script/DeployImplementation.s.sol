pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {Metrom} from "../src/Metrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract DeployImplementation is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        Metrom _metrom = new Metrom();
        console2.log("Implementation address: ", address(_metrom));

        vm.stopBroadcast();
    }
}
