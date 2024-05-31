pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom, CreateBundle, ClaimFeeBundle, ReadonlyCampaign} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract CollectFeesTest is BaseTest {
    function test_failForbidden() public {
        ClaimFeeBundle[] memory _bundles = new ClaimFeeBundle[](0);
        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.claimFees(_bundles);
    }

    function test_successNoBundles() public {
        ClaimFeeBundle[] memory _bundles = new ClaimFeeBundle[](0);
        vm.prank(owner);
        metrom.claimFees(_bundles);
    }

    function test_failInvalidToken() public {
        ClaimFeeBundle memory _bundle = ClaimFeeBundle({token: address(0), receiver: address(0)});

        ClaimFeeBundle[] memory _bundles = new ClaimFeeBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidToken.selector);
        vm.prank(owner);
        metrom.claimFees(_bundles);
    }

    function test_failInvalidReceiver() public {
        ClaimFeeBundle memory _bundle = ClaimFeeBundle({token: address(1), receiver: address(0)});

        ClaimFeeBundle[] memory _bundles = new ClaimFeeBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidReceiver.selector);
        vm.prank(owner);
        metrom.claimFees(_bundles);
    }

    function test_failZeroAmount() public {
        ClaimFeeBundle memory _bundle = ClaimFeeBundle({token: address(1), receiver: address(1)});

        ClaimFeeBundle[] memory _bundles = new ClaimFeeBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.ZeroAmount.selector);
        vm.prank(owner);
        metrom.claimFees(_bundles);
    }

    function test_success() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10 ether);
        _mintableErc20.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10 ether);

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

        bytes32 _campaignId = metrom.campaignId(_createBundle);
        ReadonlyCampaign memory _onChainCampaign = metrom.campaignById(_campaignId);
        vm.assertEq(metrom.campaignReward(_campaignId, address(_mintableErc20)), 9.9 ether);

        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0.1 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);

        ClaimFeeBundle memory _bundle = ClaimFeeBundle({token: address(_mintableErc20), receiver: address(this)});

        ClaimFeeBundle[] memory _bundles = new ClaimFeeBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.ClaimFee(_bundle.token, 0.1 ether, _bundle.receiver);

        vm.prank(owner);
        metrom.claimFees(_bundles);

        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0.1 ether);
    }
}
