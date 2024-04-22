pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetFeeTest is BaseTest {
    function test_setFeeFailForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setFee(10);
    }

    function test_setFeeFailInvalid() public {
        vm.expectRevert(IMetrom.InvalidFee.selector);
        vm.prank(owner);
        metrom.setFee(uint32(MAX_FEE + 1));
    }

    function test_setFeeSuccess() public {
        vm.assertEq(metrom.fee(), fee);

        uint32 _newFee = uint32(10_000);
        vm.prank(owner);
        metrom.setFee(_newFee);

        vm.assertEq(metrom.fee(), _newFee);
    }

    function testFuzz_setFee(uint32 _newFee) public {
        vm.assume(_newFee < MAX_FEE);

        vm.assertEq(metrom.fee(), fee);

        vm.prank(owner);
        metrom.setFee(_newFee);

        vm.assertEq(metrom.fee(), _newFee);
    }
}
