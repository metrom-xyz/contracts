pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE, IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract TransferOwnershipTest is BaseTest {
    function test_failZeroAddressOwner() public {
        vm.expectRevert(IMetrom.InvalidOwner.selector);
        metrom.transferOwnership(address(0));
    }

    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.transferOwnership(address(10));
    }

    function test_success() public {
        vm.assertEq(metrom.owner(), owner);

        address _newOwner = address(10001);

        vm.expectEmit();
        emit IMetrom.TransferOwnership(_newOwner);

        vm.prank(owner);
        metrom.transferOwnership(_newOwner);

        vm.assertEq(metrom.pendingOwner(), _newOwner);
        vm.assertEq(metrom.owner(), owner);
    }

    function testFuzz_success(address _newOwner) public {
        vm.assume(_newOwner != address(0));

        vm.assertEq(metrom.owner(), owner);

        vm.expectEmit();
        emit IMetrom.TransferOwnership(_newOwner);

        vm.prank(owner);
        metrom.transferOwnership(_newOwner);

        vm.assertEq(metrom.pendingOwner(), _newOwner);
        vm.assertEq(metrom.owner(), owner);
    }
}
