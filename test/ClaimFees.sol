pragma solidity 0.8.28;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {
    IMetrom,
    CreateRewardsCampaignBundle,
    CreatePointsCampaignBundle,
    ClaimFeeBundle,
    RewardAmount
} from "../src/IMetrom.sol";
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

    function test_failZeroAddressRewardToken() public {
        ClaimFeeBundle memory _bundle = ClaimFeeBundle({token: address(0), receiver: address(0)});

        ClaimFeeBundle[] memory _bundles = new ClaimFeeBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.ZeroAddressRewardToken.selector);
        vm.prank(owner);
        metrom.claimFees(_bundles);
    }

    function test_failZeroAddressReceiver() public {
        ClaimFeeBundle memory _bundle = ClaimFeeBundle({token: address(1), receiver: address(0)});

        ClaimFeeBundle[] memory _bundles = new ClaimFeeBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.ZeroAddressReceiver.selector);
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

    function test_successRewardsCampaign() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10 ether);
        _mintableErc20.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10 ether);
        setMinimumRewardRate(address(_mintableErc20), 1);

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(_mintableErc20), amount: 10 ether});

        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: _rewards
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](0);

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundles);

        vm.assertEq(
            metrom.campaignReward(metrom.rewardsCampaignId(_createRewardsCampaignBundle), address(_mintableErc20)),
            9.9 ether
        );

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

    function test_successPointsCampaign() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 0.5 ether);
        _mintableErc20.approve(address(metrom), 0.5 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0.5 ether);
        setMinimumFeeRate(address(_mintableErc20), 1 ether);

        CreatePointsCampaignBundle memory _createPointsCampaignBundle = CreatePointsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + 30 minutes),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            points: 10 ether,
            feeToken: address(_mintableErc20)
        });

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = _createPointsCampaignBundle;

        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);

        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0.5 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);

        ClaimFeeBundle memory _bundle = ClaimFeeBundle({token: address(_mintableErc20), receiver: address(this)});

        ClaimFeeBundle[] memory _bundles = new ClaimFeeBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.ClaimFee(_bundle.token, 0.5 ether, _bundle.receiver);

        vm.prank(owner);
        metrom.claimFees(_bundles);

        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0.5 ether);
    }
}
