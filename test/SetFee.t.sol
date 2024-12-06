pragma solidity 0.8.28;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {UNIT, IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetFeeTest is BaseTest {
    function test_failInvalid() public {
        vm.expectRevert(IMetrom.InvalidFee.selector);
        vm.prank(owner);
        metrom.setFee(uint32(UNIT));
    }

    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setFee(10);
    }

    function test_success() public {
        vm.assertEq(metrom.fee(), fee);

        uint32 _newFee = uint32(10_000);
        vm.prank(owner);
        metrom.setFee(_newFee);

        vm.assertEq(metrom.fee(), _newFee);
    }

    function testFuzz_success(uint32 _newFee) public {
        vm.assume(_newFee < UNIT);

        vm.assertEq(metrom.fee(), fee);

        vm.prank(owner);
        metrom.setFee(_newFee);

        vm.assertEq(metrom.fee(), _newFee);
    }
}
