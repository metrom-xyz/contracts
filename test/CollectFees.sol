pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom, CreateBundle, CollectFeesBundle, ReadonlyCampaign} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract CollectFeesTest is BaseTest {
    function test_failForbidden() public {
        CollectFeesBundle[] memory _bundles = new CollectFeesBundle[](0);
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.collectFees(_bundles);
    }

    function test_successNoBundles() public {
        CollectFeesBundle[] memory _bundles = new CollectFeesBundle[](0);
        vm.prank(owner);
        metrom.collectFees(_bundles);
    }

    function test_failInvalidToken() public {
        CollectFeesBundle memory _bundle = CollectFeesBundle({token: address(0), receiver: address(0)});

        CollectFeesBundle[] memory _bundles = new CollectFeesBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidToken.selector);
        vm.prank(owner);
        metrom.collectFees(_bundles);
    }

    function test_failInvalidReceiver() public {
        CollectFeesBundle memory _bundle = CollectFeesBundle({token: address(1), receiver: address(0)});

        CollectFeesBundle[] memory _bundles = new CollectFeesBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidReceiver.selector);
        vm.prank(owner);
        metrom.collectFees(_bundles);
    }

    function test_failZeroAmount() public {
        CollectFeesBundle memory _bundle = CollectFeesBundle({token: address(1), receiver: address(1)});

        CollectFeesBundle[] memory _bundles = new CollectFeesBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.ZeroAmount.selector);
        vm.prank(owner);
        metrom.collectFees(_bundles);
    }

    function test_success() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10.1 ether);
        _mintableErc20.approve(address(metrom), 10.1 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10.1 ether);

        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(_mintableErc20);

        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = 10 ether;

        CreateBundle memory _createBundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _createBundles = new CreateBundle[](1);
        _createBundles[0] = _createBundle;

        metrom.createCampaigns(_createBundles);

        vm.assertEq(metrom.accruedFees(address(_mintableErc20)), 0.1 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);

        CollectFeesBundle memory _bundle = CollectFeesBundle({token: address(_mintableErc20), receiver: address(this)});

        CollectFeesBundle[] memory _bundles = new CollectFeesBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.CollectFee(_bundle.token, 0.1 ether, _bundle.receiver);

        vm.prank(owner);
        metrom.collectFees(_bundles);

        vm.assertEq(metrom.accruedFees(address(_mintableErc20)), 0 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0.1 ether);
    }
}
