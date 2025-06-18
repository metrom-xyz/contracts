pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";

import {Metrom} from "../src/Metrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract DeployFull is Script {
    function run(
        address _owner,
        address _updater,
        uint32 _fee,
        uint32 _minimumCampaignDuration,
        uint32 _maximumCampaignDuration
    ) public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        ERC1967Proxy _metrom = new ERC1967Proxy(
            address(new Metrom()),
            abi.encodeWithSelector(
                Metrom.initialize.selector, _owner, _updater, _fee, _minimumCampaignDuration, _maximumCampaignDuration
            )
        );
        console2.log("Metrom address: ", address(_metrom));

        vm.stopBroadcast();
    }
}
