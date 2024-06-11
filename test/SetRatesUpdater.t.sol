pragma solidity 0.8.26;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetRatesUpdaterTest is BaseTest {
    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setRatesUpdater(address(20));
    }

    function test_failZeroAddressRatesUpdater() public {
        vm.expectRevert(IMetrom.ZeroAddressRatesUpdater.selector);
        vm.prank(owner);
        metrom.setRatesUpdater(address(0));
    }

    function test_success() public {
        vm.assertEq(metrom.ratesUpdater(), ratesUpdater);

        address _newUpdater = address(20);
        vm.prank(owner);
        metrom.setRatesUpdater(_newUpdater);

        vm.assertEq(metrom.ratesUpdater(), _newUpdater);
    }

    function testFuzz_success(address _newUpdater) public {
        vm.assume(_newUpdater != address(0));

        vm.assertEq(metrom.ratesUpdater(), ratesUpdater);

        vm.prank(owner);
        metrom.setRatesUpdater(_newUpdater);

        vm.assertEq(metrom.ratesUpdater(), _newUpdater);
    }
}
