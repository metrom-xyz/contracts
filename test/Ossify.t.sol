pragma solidity 0.8.28;

import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {Initializable} from "oz-up/proxy/utils/Initializable.sol";

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract InitializeTest is BaseTest {
    function test_failNotOwner() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.ossify();
    }

    function test_success() public {
        vm.assertEq(metrom.ossified(), false);

        vm.expectEmit();
        emit IMetrom.Ossify();

        vm.prank(owner);
        metrom.ossify();

        vm.assertEq(metrom.ossified(), true);
    }
}
