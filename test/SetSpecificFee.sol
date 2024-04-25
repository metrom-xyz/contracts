pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetSpecificFeeTest is BaseTest {
    function test_failInvalidAccount() public {
        vm.expectRevert(IMetrom.InvalidAccount.selector);
        metrom.setSpecificFee(address(0), uint32(MAX_FEE - 1));
    }

    function test_failInvalidFee() public {
        vm.expectRevert(IMetrom.InvalidSpecificFee.selector);
        metrom.setSpecificFee(address(1), uint32(MAX_FEE + 1));
    }

    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setSpecificFee(address(1), 10);
    }

    function test_success() public {
        address _account = address(1);

        vm.assertEq(metrom.specificFeeFor(_account).fee, 0);
        vm.assertEq(metrom.specificFeeFor(_account).none, false);

        uint32 _newFee = uint32(10_000);
        vm.prank(owner);
        metrom.setSpecificFee(_account, _newFee);

        vm.assertEq(metrom.specificFeeFor(_account).fee, _newFee);
        vm.assertEq(metrom.specificFeeFor(_account).none, false);
    }

    function test_successNone() public {
        address _account = address(1);

        vm.assertEq(metrom.specificFeeFor(_account).fee, 0);
        vm.assertEq(metrom.specificFeeFor(_account).none, false);

        vm.prank(owner);
        metrom.setSpecificFee(_account, uint32(0));

        vm.assertEq(metrom.specificFeeFor(_account).fee, 0);
        vm.assertEq(metrom.specificFeeFor(_account).none, true);
    }

    function testFuzz_success(address _account, uint32 _newSpecificFee) public {
        vm.assume(_account != address(0));
        vm.assume(_newSpecificFee < MAX_FEE);

        vm.assertEq(metrom.specificFeeFor(_account).fee, 0);
        vm.assertEq(metrom.specificFeeFor(_account).none, false);

        vm.prank(owner);
        metrom.setSpecificFee(_account, _newSpecificFee);

        vm.assertEq(metrom.specificFeeFor(_account).fee, _newSpecificFee);
        vm.assertEq(metrom.specificFeeFor(_account).none, _newSpecificFee == 0);
    }
}
