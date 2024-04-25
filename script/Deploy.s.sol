pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Metrom} from "../src/Metrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract Deploy is Script {
    function run(
        address _owner,
        address _updater,
        uint32 _fee,
        uint32 _minimumCampaignDuration,
        uint32 _maximumCampaignDuration
    ) public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        Metrom _metrom = new Metrom(_owner, _updater, _fee, _minimumCampaignDuration, _maximumCampaignDuration);
        console2.log("Metrom address: ", address(_metrom));

        vm.stopBroadcast();
    }
}
