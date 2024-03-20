pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {MetromCampaign} from "../src/MetromCampaign.sol";
import {MetromCampaignFactory} from "../src/MetromCampaignFactory.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract Deploy is Script {
    function run(address _owner, address _updater, address _feeReceiver, uint32 _fee) public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        MetromCampaign _campaign = new MetromCampaign();
        console2.log("Campaign implementation address: ", address(_campaign));

        MetromCampaignFactory _campaignFactory =
            new MetromCampaignFactory(_owner, _updater, address(_campaign), _feeReceiver, _fee);
        console2.log("Campaign factory address: ", address(_campaignFactory));

        vm.stopBroadcast();
    }
}
