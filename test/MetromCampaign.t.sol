pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {MetromCampaign} from "../src/MetromCampaign.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract MetromCampaignTest is Test {
    MetromCampaign public campaign;

    function setUp() public {
        campaign = new MetromCampaign();
    }
}
