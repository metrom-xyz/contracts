pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetMinimumCampaignDurationTest is BaseTest {
    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setMinimumCampaignDuration(10);
    }

    function test_success() public {
        vm.assertEq(metrom.minimumCampaignDuration(), minimumCampaignDuration);

        uint32 _newMinimumCampaignDuration = uint32(10_000);
        vm.prank(owner);
        metrom.setMinimumCampaignDuration(_newMinimumCampaignDuration);

        vm.assertEq(metrom.minimumCampaignDuration(), _newMinimumCampaignDuration);
    }

    function testFuzz_success(uint32 _newMinimumCampaignDuration) public {
        vm.assertEq(metrom.minimumCampaignDuration(), minimumCampaignDuration);

        vm.prank(owner);
        metrom.setMinimumCampaignDuration(_newMinimumCampaignDuration);

        vm.assertEq(metrom.minimumCampaignDuration(), _newMinimumCampaignDuration);
    }
}
