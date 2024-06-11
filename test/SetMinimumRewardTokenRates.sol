pragma solidity 0.8.26;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE, IMetrom, CreateBundle, SetMinimumRewardTokenRateBundle, ReadonlyCampaign} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract SetMinimumRewardTokenRatesTest is BaseTest {
    function test_failForbidden() public {
        SetMinimumRewardTokenRateBundle[] memory _bundles = new SetMinimumRewardTokenRateBundle[](0);

        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.setMinimumRewardTokenRates(_bundles);
    }

    function test_successNoBundles() public {
        SetMinimumRewardTokenRateBundle[] memory _bundles = new SetMinimumRewardTokenRateBundle[](0);

        vm.prank(ratesUpdater);
        metrom.setMinimumRewardTokenRates(_bundles);
    }

    function test_failZeroAddressToken() public {
        SetMinimumRewardTokenRateBundle memory _bundle =
            SetMinimumRewardTokenRateBundle({token: address(0), minimumRate: 0});

        SetMinimumRewardTokenRateBundle[] memory _bundles = new SetMinimumRewardTokenRateBundle[](1);
        _bundles[0] = _bundle;

        vm.prank(ratesUpdater);
        vm.expectRevert(IMetrom.InvalidToken.selector);
        metrom.setMinimumRewardTokenRates(_bundles);
    }

    function test_failDuplicate() public {
        SetMinimumRewardTokenRateBundle memory _bundle1 =
            SetMinimumRewardTokenRateBundle({token: address(1), minimumRate: 10});
        SetMinimumRewardTokenRateBundle memory _bundle2 =
            SetMinimumRewardTokenRateBundle({token: address(1), minimumRate: 11});

        SetMinimumRewardTokenRateBundle[] memory _bundles = new SetMinimumRewardTokenRateBundle[](2);
        _bundles[0] = _bundle1;
        _bundles[1] = _bundle2;

        vm.prank(ratesUpdater);
        vm.expectRevert(IMetrom.DuplicatedMinimumRewardTokenRate.selector);
        metrom.setMinimumRewardTokenRates(_bundles);
    }

    function test_successSingleRepeatedUpdate() public {
        address _token = address(100000000001);
        vm.assertEq(metrom.minimumRewardTokenRate(_token), 0);

        uint256 _newRate = 10;
        SetMinimumRewardTokenRateBundle memory _bundle =
            SetMinimumRewardTokenRateBundle({token: _token, minimumRate: _newRate});

        SetMinimumRewardTokenRateBundle[] memory _bundles = new SetMinimumRewardTokenRateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token, _newRate);

        vm.prank(ratesUpdater);
        metrom.setMinimumRewardTokenRates(_bundles);

        vm.assertEq(metrom.minimumRewardTokenRate(_token), _newRate);

        // update a second time

        _newRate = 100;

        _bundle = SetMinimumRewardTokenRateBundle({token: _token, minimumRate: _newRate});

        _bundles = new SetMinimumRewardTokenRateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token, _newRate);

        vm.prank(ratesUpdater);
        metrom.setMinimumRewardTokenRates(_bundles);

        vm.assertEq(metrom.minimumRewardTokenRate(_token), _newRate);
    }

    function test_successMultipleRepeatedUpdate() public {
        address _token1 = address(100000000001);
        address _token2 = address(100000000002);
        vm.assertEq(metrom.minimumRewardTokenRate(_token1), 0);
        vm.assertEq(metrom.minimumRewardTokenRate(_token2), 0);

        uint256 _newRate1 = 10;
        uint256 _newRate2 = 24 ether;
        SetMinimumRewardTokenRateBundle memory _bundle1 =
            SetMinimumRewardTokenRateBundle({token: _token1, minimumRate: _newRate1});
        SetMinimumRewardTokenRateBundle memory _bundle2 =
            SetMinimumRewardTokenRateBundle({token: _token2, minimumRate: _newRate2});

        SetMinimumRewardTokenRateBundle[] memory _bundles = new SetMinimumRewardTokenRateBundle[](2);
        _bundles[0] = _bundle1;
        _bundles[1] = _bundle2;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token1, _newRate1);
        emit IMetrom.SetMinimumRewardTokenRate(_token2, _newRate2);

        vm.prank(ratesUpdater);
        metrom.setMinimumRewardTokenRates(_bundles);

        vm.assertEq(metrom.minimumRewardTokenRate(_token1), _newRate1);
        vm.assertEq(metrom.minimumRewardTokenRate(_token2), _newRate2);

        // update a second time

        _newRate1 = 100019277;
        _newRate2 = 123.19 ether;

        _bundle1 = SetMinimumRewardTokenRateBundle({token: _token1, minimumRate: _newRate1});
        _bundle2 = SetMinimumRewardTokenRateBundle({token: _token2, minimumRate: _newRate2});

        _bundles = new SetMinimumRewardTokenRateBundle[](2);
        _bundles[0] = _bundle1;
        _bundles[1] = _bundle2;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token1, _newRate1);
        emit IMetrom.SetMinimumRewardTokenRate(_token2, _newRate2);

        vm.prank(ratesUpdater);
        metrom.setMinimumRewardTokenRates(_bundles);

        vm.assertEq(metrom.minimumRewardTokenRate(_token1), _newRate1);
        vm.assertEq(metrom.minimumRewardTokenRate(_token2), _newRate2);
    }

    function testFuzz_successSingleUpdate(address _token, uint256 _newRate) public {
        vm.assume(_token != address(0));

        vm.assertEq(metrom.minimumRewardTokenRate(_token), 0);

        SetMinimumRewardTokenRateBundle memory _bundle =
            SetMinimumRewardTokenRateBundle({token: _token, minimumRate: _newRate});

        SetMinimumRewardTokenRateBundle[] memory _bundles = new SetMinimumRewardTokenRateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token, _newRate);

        vm.prank(ratesUpdater);
        metrom.setMinimumRewardTokenRates(_bundles);

        vm.assertEq(metrom.minimumRewardTokenRate(_token), _newRate);
    }

    function testFuzz_successMultipleUpdate(address _token1, address _token2, uint256 _newRate1, uint256 _newRate2)
        public
    {
        vm.assume(_token1 != address(0));
        vm.assume(_token2 != address(0));
        vm.assume(_token1 != _token2);

        vm.assertEq(metrom.minimumRewardTokenRate(_token1), 0);
        vm.assertEq(metrom.minimumRewardTokenRate(_token2), 0);

        SetMinimumRewardTokenRateBundle memory _bundle1 =
            SetMinimumRewardTokenRateBundle({token: _token1, minimumRate: _newRate1});
        SetMinimumRewardTokenRateBundle memory _bundle2 =
            SetMinimumRewardTokenRateBundle({token: _token2, minimumRate: _newRate2});

        SetMinimumRewardTokenRateBundle[] memory _bundles = new SetMinimumRewardTokenRateBundle[](2);
        _bundles[0] = _bundle1;
        _bundles[1] = _bundle2;

        vm.expectEmit();
        emit IMetrom.SetMinimumRewardTokenRate(_token1, _newRate1);
        emit IMetrom.SetMinimumRewardTokenRate(_token2, _newRate2);

        vm.prank(ratesUpdater);
        metrom.setMinimumRewardTokenRates(_bundles);

        vm.assertEq(metrom.minimumRewardTokenRate(_token1), _newRate1);
        vm.assertEq(metrom.minimumRewardTokenRate(_token2), _newRate2);
    }
}
