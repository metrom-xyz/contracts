pragma solidity 0.8.28;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {IMetrom, SetMinimumTokenRateBundle} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetMinimumTokenRatesTest is BaseTest {
    function test_failForbidden() public {
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setMinimumTokenRates(new SetMinimumTokenRateBundle[](0), new SetMinimumTokenRateBundle[](1));
    }

    function test_successNoBundles() public {
        vm.prank(updater);
        metrom.setMinimumTokenRates(new SetMinimumTokenRateBundle[](0), new SetMinimumTokenRateBundle[](0));
    }

    function test_failZeroAddressTokenRewardsRate() public {
        SetMinimumTokenRateBundle[] memory _bundles = new SetMinimumTokenRateBundle[](1);
        _bundles[0] = SetMinimumTokenRateBundle({token: address(0), minimumRate: 0});

        vm.prank(updater);
        vm.expectRevert(IMetrom.ZeroAddressRewardToken.selector);
        metrom.setMinimumTokenRates(_bundles, new SetMinimumTokenRateBundle[](0));
    }

    function test_failZeroAddressTokenFeesRate() public {
        SetMinimumTokenRateBundle[] memory _bundles = new SetMinimumTokenRateBundle[](1);
        _bundles[0] = SetMinimumTokenRateBundle({token: address(0), minimumRate: 0});

        vm.prank(updater);
        vm.expectRevert(IMetrom.ZeroAddressFeeToken.selector);
        metrom.setMinimumTokenRates(new SetMinimumTokenRateBundle[](0), _bundles);
    }

    function test_successSingleRepeatedRewardsRateUpdate() public {
        address _token = address(100000000001);
        vm.assertEq(metrom.minimumRewardTokenRate(_token), 0);

        uint256 _newRate = 10;
        SetMinimumTokenRateBundle memory _bundle = SetMinimumTokenRateBundle({token: _token, minimumRate: _newRate});

        SetMinimumTokenRateBundle[] memory _bundles = new SetMinimumTokenRateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token, _newRate);

        vm.prank(updater);
        metrom.setMinimumTokenRates(_bundles, new SetMinimumTokenRateBundle[](0));

        vm.assertEq(metrom.minimumRewardTokenRate(_token), _newRate);

        // update a second time

        _newRate = 100;

        _bundle = SetMinimumTokenRateBundle({token: _token, minimumRate: _newRate});

        _bundles = new SetMinimumTokenRateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token, _newRate);

        vm.prank(updater);
        metrom.setMinimumTokenRates(_bundles, new SetMinimumTokenRateBundle[](0));

        vm.assertEq(metrom.minimumRewardTokenRate(_token), _newRate);
    }

    function test_successSingleRepeatedFeeRatesUpdate() public {
        address _token = address(100000000001);
        vm.assertEq(metrom.minimumRewardTokenRate(_token), 0);

        uint256 _newRate = 10;
        SetMinimumTokenRateBundle[] memory _bundles = new SetMinimumTokenRateBundle[](1);
        _bundles[0] = SetMinimumTokenRateBundle({token: _token, minimumRate: _newRate});

        vm.expectEmit();
        emit IMetrom.SetMinimumFeeTokenRate(_token, _newRate);

        vm.prank(updater);
        metrom.setMinimumTokenRates(new SetMinimumTokenRateBundle[](0), _bundles);

        vm.assertEq(metrom.minimumFeeTokenRate(_token), _newRate);

        // update a second time

        _newRate = 100;
        _bundles = new SetMinimumTokenRateBundle[](1);
        _bundles[0] = SetMinimumTokenRateBundle({token: _token, minimumRate: _newRate});

        vm.expectEmit();
        emit IMetrom.SetMinimumFeeTokenRate(_token, _newRate);

        vm.prank(updater);
        metrom.setMinimumTokenRates(new SetMinimumTokenRateBundle[](0), _bundles);

        vm.assertEq(metrom.minimumFeeTokenRate(_token), _newRate);
    }

    function test_successSingleRepeatedFeesAndRewardsRateUpdate() public {
        address _rewardToken = address(100000000001);
        vm.assertEq(metrom.minimumRewardTokenRate(_rewardToken), 0);

        address _feeToken = address(100000000002);
        vm.assertEq(metrom.minimumFeeTokenRate(_feeToken), 0);

        uint256 _newRewardTokenRate = 10;
        SetMinimumTokenRateBundle[] memory _rewardsRateBundles = new SetMinimumTokenRateBundle[](1);
        _rewardsRateBundles[0] = SetMinimumTokenRateBundle({token: _rewardToken, minimumRate: _newRewardTokenRate});

        uint256 _newFeeTokenRate = 11 ether;
        SetMinimumTokenRateBundle[] memory _feesRateBundles = new SetMinimumTokenRateBundle[](1);
        _feesRateBundles[0] = SetMinimumTokenRateBundle({token: _feeToken, minimumRate: _newFeeTokenRate});

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_rewardToken, _newRewardTokenRate);
        vm.expectEmit();
        emit IMetrom.SetMinimumFeeTokenRate(_feeToken, _newFeeTokenRate);

        vm.prank(updater);
        metrom.setMinimumTokenRates(_rewardsRateBundles, _feesRateBundles);

        vm.assertEq(metrom.minimumRewardTokenRate(_rewardToken), _newRewardTokenRate);
        vm.assertEq(metrom.minimumFeeTokenRate(_feeToken), _newFeeTokenRate);

        // update a second time

        _newRewardTokenRate = 100;
        _rewardsRateBundles = new SetMinimumTokenRateBundle[](1);
        _rewardsRateBundles[0] = SetMinimumTokenRateBundle({token: _rewardToken, minimumRate: _newRewardTokenRate});

        _newFeeTokenRate = 101;
        _feesRateBundles = new SetMinimumTokenRateBundle[](1);
        _feesRateBundles[0] = SetMinimumTokenRateBundle({token: _feeToken, minimumRate: _newFeeTokenRate});

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_rewardToken, _newRewardTokenRate);
        vm.expectEmit();
        emit IMetrom.SetMinimumFeeTokenRate(_feeToken, _newFeeTokenRate);

        vm.prank(updater);
        metrom.setMinimumTokenRates(_rewardsRateBundles, _feesRateBundles);

        vm.assertEq(metrom.minimumRewardTokenRate(_rewardToken), _newRewardTokenRate);
        vm.assertEq(metrom.minimumFeeTokenRate(_feeToken), _newFeeTokenRate);
    }

    function test_successMultipleRepeatedUpdateRewardsRate() public {
        address _token1 = address(100000000001);
        address _token2 = address(100000000002);
        vm.assertEq(metrom.minimumRewardTokenRate(_token1), 0);
        vm.assertEq(metrom.minimumRewardTokenRate(_token2), 0);

        uint256 _newRate1 = 10;
        uint256 _newRate2 = 24 ether;
        SetMinimumTokenRateBundle memory _bundle1 = SetMinimumTokenRateBundle({token: _token1, minimumRate: _newRate1});
        SetMinimumTokenRateBundle memory _bundle2 = SetMinimumTokenRateBundle({token: _token2, minimumRate: _newRate2});

        SetMinimumTokenRateBundle[] memory _bundles = new SetMinimumTokenRateBundle[](2);
        _bundles[0] = _bundle1;
        _bundles[1] = _bundle2;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token1, _newRate1);
        emit IMetrom.SetMinimumRewardTokenRate(_token2, _newRate2);

        vm.prank(updater);
        metrom.setMinimumTokenRates(_bundles, new SetMinimumTokenRateBundle[](0));

        vm.assertEq(metrom.minimumRewardTokenRate(_token1), _newRate1);
        vm.assertEq(metrom.minimumRewardTokenRate(_token2), _newRate2);

        // update a second time

        _newRate1 = 100019277;
        _newRate2 = 123.19 ether;

        _bundle1 = SetMinimumTokenRateBundle({token: _token1, minimumRate: _newRate1});
        _bundle2 = SetMinimumTokenRateBundle({token: _token2, minimumRate: _newRate2});

        _bundles = new SetMinimumTokenRateBundle[](2);
        _bundles[0] = _bundle1;
        _bundles[1] = _bundle2;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token1, _newRate1);
        emit IMetrom.SetMinimumRewardTokenRate(_token2, _newRate2);

        vm.prank(updater);
        metrom.setMinimumTokenRates(_bundles, new SetMinimumTokenRateBundle[](0));

        vm.assertEq(metrom.minimumRewardTokenRate(_token1), _newRate1);
        vm.assertEq(metrom.minimumRewardTokenRate(_token2), _newRate2);
    }

    function test_successMultipleRepeatedUpdateFeesRate() public {
        address _token1 = address(100000000001);
        address _token2 = address(100000000002);
        vm.assertEq(metrom.minimumFeeTokenRate(_token1), 0);
        vm.assertEq(metrom.minimumFeeTokenRate(_token2), 0);

        uint256 _newRate1 = 10;
        uint256 _newRate2 = 24 ether;
        SetMinimumTokenRateBundle[] memory _bundles = new SetMinimumTokenRateBundle[](2);
        _bundles[0] = SetMinimumTokenRateBundle({token: _token1, minimumRate: _newRate1});
        _bundles[1] = SetMinimumTokenRateBundle({token: _token2, minimumRate: _newRate2});

        vm.expectEmit();
        emit IMetrom.SetMinimumFeeTokenRate(_token1, _newRate1);
        emit IMetrom.SetMinimumFeeTokenRate(_token2, _newRate2);

        vm.prank(updater);
        metrom.setMinimumTokenRates(new SetMinimumTokenRateBundle[](0), _bundles);

        vm.assertEq(metrom.minimumFeeTokenRate(_token1), _newRate1);
        vm.assertEq(metrom.minimumFeeTokenRate(_token2), _newRate2);

        // update a second time

        _newRate1 = 100019277;
        _newRate2 = 123.19 ether;
        _bundles = new SetMinimumTokenRateBundle[](2);
        _bundles[0] = SetMinimumTokenRateBundle({token: _token1, minimumRate: _newRate1});
        _bundles[1] = SetMinimumTokenRateBundle({token: _token2, minimumRate: _newRate2});

        vm.expectEmit();
        emit IMetrom.SetMinimumFeeTokenRate(_token1, _newRate1);
        emit IMetrom.SetMinimumFeeTokenRate(_token2, _newRate2);

        vm.prank(updater);
        metrom.setMinimumTokenRates(new SetMinimumTokenRateBundle[](0), _bundles);

        vm.assertEq(metrom.minimumFeeTokenRate(_token1), _newRate1);
        vm.assertEq(metrom.minimumFeeTokenRate(_token2), _newRate2);
    }

    function testFuzz_successSingleUpdateRewardsRate(address _token, uint256 _newRate) public {
        vm.assume(_token != address(0));

        vm.assertEq(metrom.minimumRewardTokenRate(_token), 0);

        SetMinimumTokenRateBundle memory _bundle = SetMinimumTokenRateBundle({token: _token, minimumRate: _newRate});

        SetMinimumTokenRateBundle[] memory _bundles = new SetMinimumTokenRateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token, _newRate);

        vm.prank(updater);
        metrom.setMinimumTokenRates(_bundles, new SetMinimumTokenRateBundle[](0));

        vm.assertEq(metrom.minimumRewardTokenRate(_token), _newRate);
    }

    function testFuzz_successSingleUpdateFeesRate(address _token, uint256 _newRate) public {
        vm.assume(_token != address(0));

        vm.assertEq(metrom.minimumFeeTokenRate(_token), 0);

        SetMinimumTokenRateBundle[] memory _bundles = new SetMinimumTokenRateBundle[](1);
        _bundles[0] = SetMinimumTokenRateBundle({token: _token, minimumRate: _newRate});

        vm.expectEmit();
        emit IMetrom.SetMinimumFeeTokenRate(_token, _newRate);

        vm.prank(updater);
        metrom.setMinimumTokenRates(new SetMinimumTokenRateBundle[](0), _bundles);

        vm.assertEq(metrom.minimumFeeTokenRate(_token), _newRate);
    }

    function testFuzz_successMultipleUpdateRewardsRate(
        address _token1,
        address _token2,
        uint256 _newRate1,
        uint256 _newRate2
    ) public {
        vm.assume(_token1 != address(0));
        vm.assume(_token2 != address(0));
        vm.assume(_token1 != _token2);

        vm.assertEq(metrom.minimumRewardTokenRate(_token1), 0);
        vm.assertEq(metrom.minimumRewardTokenRate(_token2), 0);

        SetMinimumTokenRateBundle memory _bundle1 = SetMinimumTokenRateBundle({token: _token1, minimumRate: _newRate1});
        SetMinimumTokenRateBundle memory _bundle2 = SetMinimumTokenRateBundle({token: _token2, minimumRate: _newRate2});

        SetMinimumTokenRateBundle[] memory _bundles = new SetMinimumTokenRateBundle[](2);
        _bundles[0] = _bundle1;
        _bundles[1] = _bundle2;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token1, _newRate1);
        emit IMetrom.SetMinimumRewardTokenRate(_token2, _newRate2);

        vm.prank(updater);
        metrom.setMinimumTokenRates(_bundles, new SetMinimumTokenRateBundle[](0));

        vm.assertEq(metrom.minimumRewardTokenRate(_token1), _newRate1);
        vm.assertEq(metrom.minimumRewardTokenRate(_token2), _newRate2);
    }

    function testFuzz_successMultipleUpdateFeesRate(
        address _token1,
        address _token2,
        uint256 _newRate1,
        uint256 _newRate2
    ) public {
        vm.assume(_token1 != address(0));
        vm.assume(_token2 != address(0));
        vm.assume(_token1 != _token2);

        vm.assertEq(metrom.minimumFeeTokenRate(_token1), 0);
        vm.assertEq(metrom.minimumFeeTokenRate(_token2), 0);

        SetMinimumTokenRateBundle[] memory _bundles = new SetMinimumTokenRateBundle[](2);
        _bundles[0] = SetMinimumTokenRateBundle({token: _token1, minimumRate: _newRate1});
        _bundles[1] = SetMinimumTokenRateBundle({token: _token2, minimumRate: _newRate2});

        vm.expectEmit();
        emit IMetrom.SetMinimumFeeTokenRate(_token1, _newRate1);
        emit IMetrom.SetMinimumFeeTokenRate(_token2, _newRate2);

        vm.prank(updater);
        metrom.setMinimumTokenRates(new SetMinimumTokenRateBundle[](0), _bundles);

        vm.assertEq(metrom.minimumFeeTokenRate(_token1), _newRate1);
        vm.assertEq(metrom.minimumFeeTokenRate(_token2), _newRate2);
    }
}
