pragma solidity 0.8.26;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {UNIT, IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetFeeRebate is BaseTest {
    function test_failInvalidAccount() public {
        vm.expectRevert(IMetrom.InvalidAccount.selector);
        metrom.setFeeRebate(address(0), uint32(UNIT - 1));
    }

    function test_failInvalidRebate() public {
        vm.expectRevert(IMetrom.InvalidRebate.selector);
        metrom.setFeeRebate(address(1), uint32(UNIT + 1));
    }

    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setFeeRebate(address(1), 10);
    }

    function test_success() public {
        address _account = address(1);

        vm.assertEq(metrom.feeRebate(_account), 0);

        uint32 _newFeeRebate = uint32(10_000);
        vm.prank(owner);
        metrom.setFeeRebate(_account, _newFeeRebate);

        vm.assertEq(metrom.feeRebate(_account), _newFeeRebate);
    }

    function test_successNone() public {
        address _account = address(1);

        vm.assertEq(metrom.feeRebate(_account), 0);

        vm.prank(owner);
        metrom.setFeeRebate(_account, uint32(0));

        vm.assertEq(metrom.feeRebate(_account), 0);
    }

    function testFuzz_success(address _account, uint32 _rawFeeRebate) public {
        vm.assume(_account != address(0));
        uint32 _newFeeRebate = uint32(bound(_rawFeeRebate, 0, UNIT));

        vm.assertEq(metrom.feeRebate(_account), 0);

        vm.prank(owner);
        metrom.setFeeRebate(_account, _newFeeRebate);

        vm.assertEq(metrom.feeRebate(_account), _newFeeRebate);
    }
}
