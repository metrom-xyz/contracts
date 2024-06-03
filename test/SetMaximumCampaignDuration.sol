pragma solidity 0.8.26;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE, IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetMaximumCampaignDurationTest is BaseTest {
    function test_failInvalidMaximumCampaignDuration() public {
        uint32 _maximumCampaignDuration = metrom.maximumCampaignDuration();
        uint32 _minimumCampaignDuration = metrom.minimumCampaignDuration();

        // max campaign duration == minimum campaign duration
        vm.expectRevert(IMetrom.InvalidMaximumCampaignDuration.selector);
        metrom.setMaximumCampaignDuration(_minimumCampaignDuration);
        vm.assertEq(metrom.maximumCampaignDuration(), _maximumCampaignDuration);

        // max campaign duration < minimum campaign duration
        vm.expectRevert(IMetrom.InvalidMaximumCampaignDuration.selector);
        metrom.setMaximumCampaignDuration(_minimumCampaignDuration - 1);
        vm.assertEq(metrom.maximumCampaignDuration(), _maximumCampaignDuration);
    }

    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setMaximumCampaignDuration(10);
    }

    function test_success() public {
        vm.assertEq(metrom.maximumCampaignDuration(), maximumCampaignDuration);

        uint32 _newMinimumCampaignDuration = uint32(10_000);
        vm.prank(owner);
        metrom.setMaximumCampaignDuration(_newMinimumCampaignDuration);

        vm.assertEq(metrom.maximumCampaignDuration(), _newMinimumCampaignDuration);
    }

    function testFuzz_success(uint32 _newMaximumCampaignDuration) public {
        uint256 _minimumCampaignDuration = metrom.minimumCampaignDuration();
        vm.assume(_newMaximumCampaignDuration > _minimumCampaignDuration);

        vm.assertEq(metrom.maximumCampaignDuration(), maximumCampaignDuration);

        vm.prank(owner);
        metrom.setMaximumCampaignDuration(_newMaximumCampaignDuration);

        vm.assertEq(metrom.maximumCampaignDuration(), _newMaximumCampaignDuration);
    }
}
