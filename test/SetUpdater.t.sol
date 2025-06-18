pragma solidity 0.8.30;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetUpdaterTest is BaseTest {
    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setUpdater(address(20));
    }

    function test_failZeroAddressUpdater() public {
        vm.expectRevert(IMetrom.ZeroAddressUpdater.selector);
        vm.prank(owner);
        metrom.setUpdater(address(0));
    }

    function test_success() public {
        vm.assertEq(metrom.updater(), updater);

        address _newUpdater = address(20);
        vm.prank(owner);
        metrom.setUpdater(_newUpdater);

        vm.assertEq(metrom.updater(), _newUpdater);
    }

    function testFuzz_success(address _newUpdater) public {
        vm.assume(_newUpdater != address(0));

        vm.assertEq(metrom.updater(), updater);

        vm.prank(owner);
        metrom.setUpdater(_newUpdater);

        vm.assertEq(metrom.updater(), _newUpdater);
    }
}
