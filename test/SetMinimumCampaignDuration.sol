pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetMinimumCampaignDurationTest is BaseTest {
    function test_failInvalidMinimumCampaignDuration() public {
        uint32 _maximumCampaignDuration = metrom.maximumCampaignDuration();
        uint32 _minimumCampaignDuration = metrom.minimumCampaignDuration();

        // min campaign duration == maximum campaign duration
        vm.expectRevert(IMetrom.InvalidMinimumCampaignDuration.selector);
        metrom.setMinimumCampaignDuration(_maximumCampaignDuration);
        vm.assertEq(metrom.minimumCampaignDuration(), _minimumCampaignDuration);

        // min campaign duration > maximum campaign duration
        vm.expectRevert(IMetrom.InvalidMinimumCampaignDuration.selector);
        metrom.setMinimumCampaignDuration(_maximumCampaignDuration + 1);
        vm.assertEq(metrom.minimumCampaignDuration(), _minimumCampaignDuration);
    }

    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setMinimumCampaignDuration(10);
    }

    function test_success() public {
        uint256 _minimumCampaignDuration = metrom.minimumCampaignDuration();

        vm.assertEq(_minimumCampaignDuration, minimumCampaignDuration);

        uint32 _newMinimumCampaignDuration = uint32(_minimumCampaignDuration - 1);
        vm.prank(owner);
        metrom.setMinimumCampaignDuration(_newMinimumCampaignDuration);

        vm.assertEq(metrom.minimumCampaignDuration(), _newMinimumCampaignDuration);
    }

    function testFuzz_success(uint32 _newMinimumCampaignDuration) public {
        uint256 _maximumCampaignDuration = metrom.maximumCampaignDuration();
        vm.assume(_newMinimumCampaignDuration < _maximumCampaignDuration);

        vm.assertEq(metrom.minimumCampaignDuration(), minimumCampaignDuration);

        vm.prank(owner);
        metrom.setMinimumCampaignDuration(_newMinimumCampaignDuration);

        vm.assertEq(metrom.minimumCampaignDuration(), _newMinimumCampaignDuration);
    }
}
