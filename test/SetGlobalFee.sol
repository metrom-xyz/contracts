pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetGlobalFeeTest is BaseTest {
    function test_failInvalid() public {
        vm.expectRevert(IMetrom.InvalidGlobalFee.selector);
        vm.prank(owner);
        metrom.setGlobalFee(uint32(MAX_FEE + 1));
    }

    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setGlobalFee(10);
    }

    function test_success() public {
        vm.assertEq(metrom.globalFee(), globalFee);

        uint32 _newGlobalFee = uint32(10_000);
        vm.prank(owner);
        metrom.setGlobalFee(_newGlobalFee);

        vm.assertEq(metrom.globalFee(), _newGlobalFee);
    }

    function testFuzz_success(uint32 _newGlobalFee) public {
        vm.assume(_newGlobalFee < MAX_FEE);

        vm.assertEq(metrom.globalFee(), globalFee);

        vm.prank(owner);
        metrom.setGlobalFee(_newGlobalFee);

        vm.assertEq(metrom.globalFee(), _newGlobalFee);
    }
}
