pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract ResolvedFeeTest is BaseTest {
    function test_successNoSpecificFee() public view {
        vm.assertEq(metrom.resolvedFee(), globalFee);
    }

    function test_successSpecificFeeWithValue() public {
        address _account = address(123);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), globalFee);

        uint32 _specificFee = globalFee / 2;
        vm.prank(owner);
        metrom.setSpecificFee(_account, _specificFee);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), _specificFee);
    }

    function test_successSpecificFeeNone() public {
        address _account = address(123);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), globalFee);

        uint32 _specificFee = 0;
        vm.prank(owner);
        metrom.setSpecificFee(_account, _specificFee);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), _specificFee);
    }

    function testFuzz_successSpecificFee(uint32 _rawSpecificFee) public {
        vm.assume(_rawSpecificFee != globalFee);
        uint32 _specificFee = uint32(bound(_rawSpecificFee, 0, MAX_FEE - 1));

        address _account = address(321);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), globalFee);

        vm.prank(owner);
        metrom.setSpecificFee(_account, _specificFee);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), _specificFee);
    }
}
