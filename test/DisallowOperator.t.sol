pragma solidity 0.8.28;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {UNIT, IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract DisallowOperatorTest is BaseTest {
    function test_failInvalid() public {
        vm.expectRevert(IMetrom.ZeroAddressAccount.selector);
        metrom.disallowOperator(address(0));
    }

    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.disallowOperator(address(10));
    }

    function test_success() public {
        address _account = address(1298929292);

        vm.prank(owner);
        metrom.allowOperator(_account);

        vm.assertEq(metrom.operators(_account), true);

        vm.prank(owner);
        metrom.disallowOperator(_account);

        vm.assertEq(metrom.operators(_account), false);
    }
}
