pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract ConstructorTest is BaseTest {
    function test_failInvalidOwner() public {
        vm.expectRevert(IMetrom.InvalidOwner.selector);
        new MetromHarness(address(0), address(0), 10, 10, 10);
    }

    function test_failInvalidUpdater() public {
        vm.expectRevert(IMetrom.InvalidUpdater.selector);
        new MetromHarness(address(1), address(0), 10, 10, 10);
    }

    function test_failInvalidFee() public {
        vm.expectRevert(IMetrom.InvalidFee.selector);
        new MetromHarness(address(1), address(1), uint32(MAX_FEE + 1), 10, 10);
    }

    function test_failInvalidMinimumCampaignDuration() public {
        // minimum campaign duration > than maximum campaign duration
        vm.expectRevert(IMetrom.InvalidMinimumCampaignDuration.selector);
        new MetromHarness(address(1), address(1), uint32(10_000), 10, 8);

        // minimum campaign duration == than maximum campaign duration
        vm.expectRevert(IMetrom.InvalidMinimumCampaignDuration.selector);
        new MetromHarness(address(1), address(1), uint32(10_000), 10, 10);
    }

    function test_success() public {
        address _owner = address(1);
        address _updater = address(2);
        uint32 _fee = 10;
        uint32 _minimumCampaignDuration = 5 seconds;
        uint32 _maximumCampaignDuration = 10 seconds;

        vm.expectEmit();
        emit IMetrom.Initialize(_owner, _updater, _fee, _minimumCampaignDuration, _maximumCampaignDuration);

        MetromHarness _metrom =
            new MetromHarness(_owner, _updater, _fee, _minimumCampaignDuration, _maximumCampaignDuration);

        vm.assertEq(_metrom.owner(), _owner);
        vm.assertEq(_metrom.pendingOwner(), address(0));
        vm.assertEq(_metrom.updater(), _updater);
        vm.assertEq(_metrom.fee(), _fee);
        vm.assertEq(_metrom.minimumCampaignDuration(), _minimumCampaignDuration);
        vm.assertEq(_metrom.maximumCampaignDuration(), _maximumCampaignDuration);
    }

    function testFuzz_success(address _owner, address _updater, uint32 _fee, uint32 _minimumCampaignDuration) public {
        vm.assume(_owner != address(0));
        vm.assume(_updater != address(0));
        vm.assume(_fee <= MAX_FEE);
        vm.assume(_minimumCampaignDuration < type(uint32).max - 10 seconds);

        uint32 _maximumCampaignDuration = _minimumCampaignDuration + 10 seconds;

        vm.expectEmit();
        emit IMetrom.Initialize(_owner, _updater, _fee, _minimumCampaignDuration, _maximumCampaignDuration);

        MetromHarness _metrom =
            new MetromHarness(_owner, _updater, _fee, _minimumCampaignDuration, _maximumCampaignDuration);

        vm.assertEq(_metrom.owner(), _owner);
        vm.assertEq(_metrom.pendingOwner(), address(0));
        vm.assertEq(_metrom.updater(), _updater);
        vm.assertEq(_metrom.fee(), _fee);
        vm.assertEq(_metrom.minimumCampaignDuration(), _minimumCampaignDuration);
        vm.assertEq(_metrom.maximumCampaignDuration(), _maximumCampaignDuration);
    }
}
