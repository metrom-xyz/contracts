pragma solidity 0.8.30;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {UNIT, IMetrom, ResolvedFee} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract ResolvedReimbursementFee is BaseTest {
    function test_noRebateByAddress() public {
        vm.prank(owner);
        metrom.setReimbursementFee(10_000);
        ResolvedFee memory _fee = metrom.resolvedReimbursementFeeByAddress(address(this));
        vm.assertEq(_fee.full, 10_000);
        vm.assertEq(_fee.rebate, 0);
        vm.assertEq(_fee.resolved, 10_000);
    }

    function test_rebateByAddress() public {
        vm.prank(owner);
        metrom.setReimbursementFee(10_000);
        vm.prank(owner);
        metrom.setReimbursementFeeRebate(address(this), 500_000);
        ResolvedFee memory _fee = metrom.resolvedReimbursementFeeByAddress(address(this));
        vm.assertEq(_fee.full, 10_000);
        vm.assertEq(_fee.rebate, 500_000);
        vm.assertEq(_fee.resolved, 5_000);
    }

    function test_noRebateByCampaignId() public {
        vm.prank(owner);
        metrom.setReimbursementFee(10_000);
        ResolvedFee memory _fee = metrom.resolvedReimbursementFeeByCampaign(createFixedRewardsCampaign());
        vm.assertEq(_fee.full, 10_000);
        vm.assertEq(_fee.rebate, 0);
        vm.assertEq(_fee.resolved, 10_000);
    }

    function test_rebateByCampaignId() public {
        vm.prank(owner);
        metrom.setReimbursementFee(10_000);
        vm.prank(owner);
        metrom.setReimbursementFeeRebate(address(this), 500_000);
        ResolvedFee memory _fee = metrom.resolvedReimbursementFeeByCampaign(createFixedRewardsCampaign());
        vm.assertEq(_fee.full, 10_000);
        vm.assertEq(_fee.rebate, 500_000);
        vm.assertEq(_fee.resolved, 5_000);
    }
}
