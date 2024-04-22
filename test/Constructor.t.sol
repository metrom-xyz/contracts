pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract ConstructorTest is BaseTest {
    function test_newInvalidOwner() public {
        vm.expectRevert(IMetrom.InvalidOwner.selector);
        new MetromHarness(address(0), address(0), 10, 10);
    }

    function test_newInvalidUpdater() public {
        vm.expectRevert(IMetrom.InvalidUpdater.selector);
        new MetromHarness(address(1), address(0), 10, 10);
    }

    function test_newInvalidFee() public {
        vm.expectRevert(IMetrom.InvalidFee.selector);
        new MetromHarness(address(1), address(1), uint32(MAX_FEE + 1), 10);
    }

    function test_newSuccess() public {
        address _owner = address(1);
        address _updater = address(2);
        uint32 _fee = 10;
        uint32 _minimumCampaignDuration = 5 seconds;

        vm.expectEmit();
        emit IMetrom.Initialize(_owner, _updater, _fee, _minimumCampaignDuration);

        MetromHarness _metrom = new MetromHarness(_owner, _updater, _fee, _minimumCampaignDuration);

        vm.assertEq(_metrom.owner(), _owner);
        vm.assertEq(_metrom.pendingOwner(), address(0));
        vm.assertEq(_metrom.updater(), _updater);
        vm.assertEq(_metrom.fee(), _fee);
        vm.assertEq(_metrom.minimumCampaignDuration(), _minimumCampaignDuration);
    }

    function testFuzz_new(address _owner, address _updater, uint32 _fee, uint32 _minimumCampaignDuration) public {
        vm.assume(_owner != address(0));
        vm.assume(_updater != address(0));
        vm.assume(_fee <= MAX_FEE);

        vm.expectEmit();
        emit IMetrom.Initialize(_owner, _updater, _fee, _minimumCampaignDuration);

        MetromHarness _metrom = new MetromHarness(_owner, _updater, _fee, _minimumCampaignDuration);

        vm.assertEq(_metrom.owner(), _owner);
        vm.assertEq(_metrom.pendingOwner(), address(0));
        vm.assertEq(_metrom.updater(), _updater);
        vm.assertEq(_metrom.fee(), _fee);
        vm.assertEq(_metrom.minimumCampaignDuration(), _minimumCampaignDuration);
    }
}
