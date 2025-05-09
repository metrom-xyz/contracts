pragma solidity 0.8.28;

import {Initializable} from "oz-up/proxy/utils/Initializable.sol";

import {MetromHarness, MetromHarnessUpgraded, MetromHarnessUpgradedReinitializer} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract UpgradeTest is BaseTest {
    function test_failNotOwner() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.upgradeToAndCall(address(1234), bytes(""));
    }

    function test_failOssified() public {
        vm.prank(owner);
        metrom.ossify();
        vm.assertEq(metrom.ossified(), true);

        vm.expectRevert(IMetrom.Ossified.selector);
        vm.prank(owner);
        metrom.upgradeToAndCall(address(1234), bytes(""));
    }

    function test_failInvalidImplementation() public {
        address _implementation = address(1000001);
        vm.expectRevert();
        vm.prank(owner);
        metrom.upgradeToAndCall(_implementation, bytes(""));
    }

    function test_success() public {
        MetromHarnessUpgraded _upgraded = new MetromHarnessUpgraded();

        vm.prank(owner);
        metrom.upgradeToAndCall(address(_upgraded), bytes(""));

        vm.assertEq(MetromHarnessUpgraded(address(metrom)).upgraded(), true);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        metrom.initialize(address(1), address(1), 10, 10, 10, 11);
    }

    function test_successReinitialize() public {
        MetromHarnessUpgradedReinitializer _upgraded = new MetromHarnessUpgradedReinitializer();

        string memory _value = "definitely upgraded and reinitialized";

        vm.prank(owner);
        metrom.upgradeToAndCall(
            address(_upgraded), abi.encodeWithSelector(MetromHarnessUpgradedReinitializer.reinitialize.selector, _value)
        );

        vm.assertEq(MetromHarnessUpgradedReinitializer(address(metrom)).value(), _value);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        MetromHarnessUpgradedReinitializer(address(metrom)).reinitialize("trying to reinitialize again");
    }
}
