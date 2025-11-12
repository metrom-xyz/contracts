pragma solidity 0.8.28;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {
    IMetrom,
    CreateRewardsCampaignBundle,
    CreatePointsCampaignBundle,
    ClaimFeeBundle,
    RewardAmount,
    ReadonlyRewardsCampaign,
    RewardAmount
} from "../src/IMetrom.sol";
import {AmmPoolLiquidityRewardsCampaignCreator} from "../src/examples/AmmPoolLiquidityRewardsCampaignCreator.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract AmmPoolLiquidityRewardsCampaignCreatorTest is BaseTest {
    function test_create() public {
        AmmPoolLiquidityRewardsCampaignCreator _creator = new AmmPoolLiquidityRewardsCampaignCreator(IMetrom(metrom));

        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10 ether);
        _mintableErc20.approve(address(_creator), 10 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10 ether);
        setMinimumRewardRate(address(_mintableErc20), 1);

        uint32 _from = uint32(block.timestamp + 10);
        uint32 _to = uint32(block.timestamp + 20);

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(_mintableErc20), amount: 10 ether});

        address _poolAddress = address(1122334455);
        bytes32 _poolId = bytes32(uint256(uint160(_poolAddress)));

        bytes32 _createdCampaignId = _creator.create(_from, _to, _rewards, _poolId);

        ReadonlyRewardsCampaign memory _createdCampaign = metrom.rewardsCampaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.owner, address(_creator));
        vm.assertEq(_createdCampaign.from, _from);
        vm.assertEq(_createdCampaign.to, _to);
        vm.assertEq(_createdCampaign.kind, 1);
        vm.assertEq(_createdCampaign.data, abi.encode(_poolId));
        vm.assertEq(_createdCampaign.specificationHash, bytes32(0));
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableErc20)), 9.9 ether);
    }
}
