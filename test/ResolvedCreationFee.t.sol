pragma solidity 0.8.30;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {UNIT, IMetrom, ResolvedFee} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract ResolvedCreationFee is BaseTest {
    function test_noRebate() public {
        vm.prank(owner);
        metrom.setCreationFee(10_000);
        ResolvedFee memory _fee = metrom.resolvedRewardsCampaignCreationFee(address(this));
        vm.assertEq(_fee.full, 10_000);
        vm.assertEq(_fee.rebate, 0);
        vm.assertEq(_fee.resolved, 10_000);
    }

    function test_rebate() public {
        vm.prank(owner);
        metrom.setCreationFee(10_000);
        vm.prank(owner);
        metrom.setCreationFeeRebate(address(this), 500_000);
        ResolvedFee memory _fee = metrom.resolvedRewardsCampaignCreationFee(address(this));
        vm.assertEq(_fee.full, 10_000);
        vm.assertEq(_fee.rebate, 500_000);
        vm.assertEq(_fee.resolved, 5_000);
    }
}
