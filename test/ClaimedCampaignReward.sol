pragma solidity 0.8.28;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {
    IMetrom,
    CreateRewardsCampaignBundle,
    CreatePointsCampaignBundle,
    ClaimFeeBundle,
    DistributeRewardsBundle,
    ClaimRewardBundle,
    RewardAmount
} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract ClaimedCampaignRewardTest is BaseTest {
    function test_failNonExistentCampaign() public {
        vm.expectRevert(IMetrom.NonExistentCampaign.selector);
        metrom.claimedCampaignReward(bytes32(0), address(0), address(0));
    }

    function test_success() public {
        vm.etch(address(1234), address(new MintableERC20("Test", "TST")).code);
        MintableERC20 _mintableErc20 = MintableERC20(address(1234));
        _mintableErc20.mint(address(this), 1000 ether);
        _mintableErc20.approve(address(metrom), 1000 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 1000 ether);
        setMinimumRewardRate(address(_mintableErc20), 1);

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(_mintableErc20), amount: 1000 ether});

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
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0 ether);

        // the following root is taken by constructing a tree
        // including the following 2 claims:
        // [
        //     {
        //         account: "0x0000000000000000000000000000000000000009",
        //         token: "0x00000000000000000000000000000000000004d2",
        //         amount: 90000000000000000000
        //     },
        //     {
        //         account: "0x0000000000000000000000000000000000000002",
        //         token: "0x0000000000000000000000000000000000000003",
        //         amount: 900000000000000000000
        //     }
        // ]
        // then the provided proof at claim time is the one for the second claim

        bytes32 _createdCampaignId = metrom.rewardsCampaignId(_createRewardsCampaignBundle);
        {
            bytes32 _root = bytes32(0xb1ba26940192dab1dbb383cfc69674e93fb8011037f51703624b66d5238661b5);
            DistributeRewardsBundle memory _distributeRewardBundle =
                DistributeRewardsBundle({campaignId: _createdCampaignId, root: _root, dataHash: bytes32("foo")});
            DistributeRewardsBundle[] memory _distributeRewardBundles = new DistributeRewardsBundle[](1);
            _distributeRewardBundles[0] = _distributeRewardBundle;

            vm.prank(updater);
            metrom.distributeRewards(_distributeRewardBundles);
            vm.assertEq(metrom.rewardsCampaignById(metrom.rewardsCampaignId(_createRewardsCampaignBundle)).root, _root);
        }

        bytes32[] memory _proof = new bytes32[](1);
        _proof[0] = bytes32(0x8d67ceed8123952c42fc6264420185abfbffce5ebebea680b578e3a882e48b85);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: _createdCampaignId,
            proof: _proof,
            token: address(_mintableErc20),
            amount: 90 ether,
            receiver: address(7)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        vm.prank(address(9));
        metrom.claimRewards(_bundles);

        vm.assertEq(metrom.claimedCampaignReward(_createdCampaignId, address(_mintableErc20), address(0)), 0 ether);
        vm.assertEq(metrom.claimedCampaignReward(_createdCampaignId, address(_mintableErc20), address(9)), 90 ether);
    }
}
