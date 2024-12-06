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
contract CampaignRewardTest is BaseTest {
    function test_failNonExistentCampaign() public {
        vm.expectRevert(IMetrom.NonExistentCampaign.selector);
        metrom.campaignReward(bytes32(0), address(0));
    }

    function test_success() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10 ether);
        _mintableErc20.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10 ether);
        setMinimumRewardRate(address(_mintableErc20), 1);

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(_mintableErc20), amount: 10 ether});

        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewards: _rewards
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](0);

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundles);

        bytes32 _campaignId = metrom.rewardsCampaignId(_createRewardsCampaignBundle);

        vm.assertEq(metrom.campaignReward(_campaignId, address(_mintableErc20)), 9.9 ether);
    }
}
