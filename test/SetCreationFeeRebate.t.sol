pragma solidity 0.8.28;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {UNIT, IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetCreationFeeRebate is BaseTest {
    function test_failZeroAddressAccount() public {
        vm.expectRevert(IMetrom.ZeroAddressAccount.selector);
        metrom.setCreationFeeRebate(address(0), uint32(UNIT - 1));
    }

    function test_failRebateTooHigh() public {
        vm.expectRevert(IMetrom.RebateTooHigh.selector);
        metrom.setCreationFeeRebate(address(1), uint32(UNIT + 1));
    }

    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setCreationFeeRebate(address(1), 10);
    }

    function test_success() public {
        address _account = address(1);

        vm.assertEq(metrom.creationFeeRebate(_account), 0);

        uint32 _newFeeRebate = uint32(10_000);
        vm.prank(owner);
        metrom.setCreationFeeRebate(_account, _newFeeRebate);

        vm.assertEq(metrom.creationFeeRebate(_account), _newFeeRebate);
    }

    function test_successNone() public {
        address _account = address(1);

        vm.assertEq(metrom.creationFeeRebate(_account), 0);

        vm.prank(owner);
        metrom.setCreationFeeRebate(_account, uint32(0));

        vm.assertEq(metrom.creationFeeRebate(_account), 0);
    }

    function testFuzz_success(address _account, uint32 _rawFeeRebate) public {
        vm.assume(_account != address(0));
        uint32 _newFeeRebate = uint32(bound(_rawFeeRebate, 0, UNIT));

        vm.assertEq(metrom.creationFeeRebate(_account), 0);

        vm.prank(owner);
        metrom.setCreationFeeRebate(_account, _newFeeRebate);

        vm.assertEq(metrom.creationFeeRebate(_account), _newFeeRebate);
    }
}
