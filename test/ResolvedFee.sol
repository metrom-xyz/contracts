pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE, UNIT, IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract ResolvedFeeTest is BaseTest {
    function test_successNoFeeRebate() public view {
        vm.assertEq(metrom.resolvedFee(), fee);
    }

    function test_successFeeRebateWithValue() public {
        address _account = address(123);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), fee);

        uint32 _feeRebate = UNIT / 2; // 50% of the standard fee
        vm.prank(owner);
        metrom.setFeeRebate(_account, _feeRebate);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), fee / 2);
    }

    function test_successFeeRebateWithValueOnFeeChange() public {
        address _account = address(123);

        uint32 _fee = 50_000; // 5%
        vm.prank(owner);
        metrom.setFee(_fee);
        vm.assertEq(metrom.fee(), _fee);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), _fee);

        uint32 _feeRebate = UNIT / 4; // 25% reduction the standard fee
        vm.prank(owner);
        metrom.setFeeRebate(_account, _feeRebate);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), _fee / 4 * 3);

        _fee = 100_000; // 10%
        vm.prank(owner);
        metrom.setFee(_fee);
        vm.assertEq(metrom.fee(), _fee);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), _fee / 4 * 3);
    }

    function test_successFullFeeRebate() public {
        address _account = address(123);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), fee);

        uint32 _feeRebate = UNIT;
        vm.prank(owner);
        metrom.setFeeRebate(_account, _feeRebate);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), 0);
    }

    function testFuzz_successFeeRebate(uint32 _rawRebate) public {
        uint32 _feeRebate = uint32(bound(_rawRebate, 0, UNIT));

        address _account = address(321);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), fee);

        vm.prank(owner);
        metrom.setFeeRebate(_account, _feeRebate);

        uint32 _onChainRebate = metrom.feeRebate(_account);
        vm.assertEq(_onChainRebate, _feeRebate);

        vm.prank(_account);
        vm.assertEq(metrom.resolvedFee(), uint32(uint64(fee) * (UNIT - _onChainRebate) / UNIT));
    }
}
