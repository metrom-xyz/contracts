pragma solidity 0.8.26;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {
    MAX_FEE, IMetrom, CreateBundle, DistributeRewardsBundle, ReadonlyCampaign, RewardAmount
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

    function test_failInvalidRoot() public {
        DistributeRewardsBundle memory _bundle =
            DistributeRewardsBundle({campaignId: bytes32(0), root: bytes32(0), data: bytes32(0)});

        DistributeRewardsBundle[] memory _bundles = new DistributeRewardsBundle[](1);
        _bundles[0] = _bundle;

        vm.prank(updater);
        vm.expectRevert(IMetrom.InvalidRoot.selector);
        metrom.distributeRewards(_bundles);
    }

    function test_failInvalidData() public {
        DistributeRewardsBundle memory _bundle =
            DistributeRewardsBundle({campaignId: bytes32(0), root: bytes32("test"), data: bytes32(0)});

        DistributeRewardsBundle[] memory _bundles = new DistributeRewardsBundle[](1);
        _bundles[0] = _bundle;

        vm.prank(updater);
        vm.expectRevert(IMetrom.InvalidData.selector);
        metrom.distributeRewards(_bundles);
    }

    function test_failNonExistentCampaign() public {
        DistributeRewardsBundle memory _bundle =
            DistributeRewardsBundle({campaignId: bytes32(0), root: bytes32("test"), data: bytes32("test")});

        DistributeRewardsBundle[] memory _bundles = new DistributeRewardsBundle[](1);
        _bundles[0] = _bundle;

        vm.prank(updater);
        vm.expectRevert(IMetrom.NonExistentCampaign.selector);
        metrom.distributeRewards(_bundles);
    }

    function test_failDuplicate() public {
        DistributeRewardsBundle memory _bundle1 =
            DistributeRewardsBundle({campaignId: bytes32(0), root: bytes32("test1"), data: bytes32("test1")});
        DistributeRewardsBundle memory _bundle2 =
            DistributeRewardsBundle({campaignId: bytes32(0), root: bytes32("test2"), data: bytes32("test2")});

        DistributeRewardsBundle[] memory _bundles = new DistributeRewardsBundle[](2);
        _bundles[0] = _bundle1;
        _bundles[1] = _bundle2;

        vm.prank(updater);
        vm.expectRevert(IMetrom.DuplicatedDistribution.selector);
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

        CreateBundle memory _createBundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewards: _rewards
        });

        CreateBundle[] memory _createBundles = new CreateBundle[](1);
        _createBundles[0] = _createBundle;

        metrom.createCampaigns(_createBundles);

        DistributeRewardsBundle memory _bundle = DistributeRewardsBundle({
            campaignId: metrom.campaignId(_createBundle),
            root: bytes32("test"),
            data: bytes32("test")
        });
        DistributeRewardsBundle[] memory _bundles = new DistributeRewardsBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.DistributeReward(_bundle.campaignId, _bundle.root, _bundle.data);

        vm.prank(updater);
        metrom.distributeRewards(_bundles);
    }
}
