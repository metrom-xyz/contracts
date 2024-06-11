pragma solidity 0.8.26;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetCampaignsUpdaterTest is BaseTest {
    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setCampaignsUpdater(address(20));
    }

    function test_failZeroAddressCampaignsUpdater() public {
        vm.expectRevert(IMetrom.ZeroAddressCampaignsUpdater.selector);
        vm.prank(owner);
        metrom.setCampaignsUpdater(address(0));
    }

    function test_success() public {
        vm.assertEq(metrom.campaignsUpdater(), campaignsUpdater);

        address _newUpdater = address(20);
        vm.prank(owner);
        metrom.setCampaignsUpdater(_newUpdater);

        vm.assertEq(metrom.campaignsUpdater(), _newUpdater);
    }

    function testFuzz_success(address _newUpdater) public {
        vm.assume(_newUpdater != address(0));

        vm.assertEq(metrom.campaignsUpdater(), campaignsUpdater);

        vm.prank(owner);
        metrom.setCampaignsUpdater(_newUpdater);

        vm.assertEq(metrom.campaignsUpdater(), _newUpdater);
    }
}
