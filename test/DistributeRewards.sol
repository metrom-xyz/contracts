pragma solidity 0.8.28;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {
    IMetrom,
    CreateRewardsCampaignBundle,
    CreatePointsCampaignBundle,
    DistributeRewardsBundle,
    RewardAmount
} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract DistributeRewardsTest is BaseTest {
    function test_failForbidden() public {
        DistributeRewardsBundle[] memory _bundles = new DistributeRewardsBundle[](0);

        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.distributeRewards(_bundles);
    }

    function test_successNoBundles() public {
        DistributeRewardsBundle[] memory _bundles = new DistributeRewardsBundle[](0);

        vm.prank(updater);
        metrom.distributeRewards(_bundles);
    }

    function test_failZeroRoot() public {
        DistributeRewardsBundle memory _bundle =
            DistributeRewardsBundle({campaignId: bytes32(0), root: bytes32(0), dataHash: bytes32(0)});

        DistributeRewardsBundle[] memory _bundles = new DistributeRewardsBundle[](1);
        _bundles[0] = _bundle;

        vm.prank(updater);
        vm.expectRevert(IMetrom.ZeroRoot.selector);
        metrom.distributeRewards(_bundles);
    }

    function test_failZeroData() public {
        DistributeRewardsBundle memory _bundle =
            DistributeRewardsBundle({campaignId: bytes32(0), root: bytes32("test"), dataHash: bytes32(0)});

        DistributeRewardsBundle[] memory _bundles = new DistributeRewardsBundle[](1);
        _bundles[0] = _bundle;

        vm.prank(updater);
        vm.expectRevert(IMetrom.ZeroData.selector);
        metrom.distributeRewards(_bundles);
    }

    function test_failNonExistentCampaign() public {
        DistributeRewardsBundle memory _bundle =
            DistributeRewardsBundle({campaignId: bytes32(0), root: bytes32("test"), dataHash: bytes32("test")});

        DistributeRewardsBundle[] memory _bundles = new DistributeRewardsBundle[](1);
        _bundles[0] = _bundle;

        vm.prank(updater);
        vm.expectRevert(IMetrom.NonExistentCampaign.selector);
        metrom.distributeRewards(_bundles);
    }

    function test_successSingleCampaign() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10.1 ether);
        _mintableErc20.approve(address(metrom), 10.1 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10.1 ether);
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

        DistributeRewardsBundle memory _bundle = DistributeRewardsBundle({
            campaignId: metrom.rewardsCampaignId(_createRewardsCampaignBundle),
            root: bytes32("test"),
            dataHash: bytes32("test")
        });
        DistributeRewardsBundle[] memory _bundles = new DistributeRewardsBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.DistributeReward(_bundle.campaignId, _bundle.root, _bundle.dataHash);

        vm.prank(updater);
        metrom.distributeRewards(_bundles);
    }
}
