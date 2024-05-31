pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {
    MAX_FEE,
    IMetrom,
    CreateBundle,
    ClaimRewardBundle,
    ReadonlyCampaign,
    DistributeRewardsBundle
} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract ClaimRecoverRewards is BaseTest {
    function test_successNoBundles() public {
        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](0);
        metrom.recoverRewards(_bundles);
    }

    function test_failNotCampaignOwner() public {
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

        bytes32[] memory _proof = new bytes32[](0);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: metrom.campaignId(_createBundle),
            proof: _proof,
            token: address(1),
            amount: 10 ether,
            receiver: address(1)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.Forbidden.selector);
        vm.prank(address(1000000001));
        metrom.recoverRewards(_bundles);
    }

    function test_failInvalidReceiver() public {
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

        bytes32[] memory _proof = new bytes32[](0);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: metrom.campaignId(_createBundle),
            proof: _proof,
            token: address(1),
            amount: 10 ether,
            receiver: address(0)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidReceiver.selector);
        metrom.recoverRewards(_bundles);
    }

    function test_failInvalidToken() public {
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

        bytes32[] memory _proof = new bytes32[](0);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: metrom.campaignId(_createBundle),
            proof: _proof,
            token: address(0),
            amount: 10 ether,
            receiver: address(1)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidToken.selector);
        metrom.recoverRewards(_bundles);
    }

    function test_failZeroAmount() public {
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

        bytes32[] memory _proof = new bytes32[](0);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: metrom.campaignId(_createBundle),
            proof: _proof,
            token: address(1),
            amount: 0 ether,
            receiver: address(1)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidAmount.selector);
        metrom.recoverRewards(_bundles);
    }

    function test_failNonExistentCampaign() public {
        bytes32[] memory _proof = new bytes32[](0);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: bytes32(0),
            proof: _proof,
            token: address(1),
            amount: 1 ether,
            receiver: address(1)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.NonExistentCampaign.selector);
        metrom.recoverRewards(_bundles);
    }

    function test_failInvalidProof() public {
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

        bytes32[] memory _proof = new bytes32[](0);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: metrom.campaignId(_createBundle),
            proof: _proof,
            token: address(1),
            amount: 1 ether,
            receiver: address(1)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidProof.selector);
        metrom.recoverRewards(_bundles);
    }

    function test_failMultipleSameClaimProcessing() public {
        vm.etch(address(1234), address(new MintableERC20("Test", "TST")).code);
        MintableERC20 _mintableErc20 = MintableERC20(address(1234));
        _mintableErc20.mint(address(this), 1000 ether);
        _mintableErc20.approve(address(metrom), 1000 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 1000 ether);

        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(_mintableErc20);

        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = 1000 ether;

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
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0 ether);

        bytes32 _createdCampaignId = metrom.campaignId(_createBundle);
        ReadonlyCampaign memory _createdCampaign = metrom.campaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.chainId, _createBundle.chainId);
        vm.assertEq(_createdCampaign.pool, _createBundle.pool);
        vm.assertEq(_createdCampaign.from, _createBundle.from);
        vm.assertEq(_createdCampaign.to, _createBundle.to);
        vm.assertEq(_createdCampaign.specification, _createBundle.specification);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(_createdCampaign.rewards.length, 1);
        vm.assertEq(_createdCampaign.rewards[0].token, address(_mintableErc20));
        vm.assertEq(_createdCampaign.rewards[0].amount, 990 ether);
        vm.assertEq(_createdCampaign.rewards[0].unclaimed, 990 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(metrom)), 1000 ether);

        // the following root is taken by constructing a tree
        // including the following 2 claims:
        // [
        //     {
        //         account: "0x0000000000000000000000000000000000000000",
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

        bytes32 _root = bytes32(0x40e9e0b48e6b5b10bcf2b72e0c7af4fe754c94bb43ef3e668c9fb535bb3554ae);
        DistributeRewardsBundle memory _distributeRewardBundle =
            DistributeRewardsBundle({campaignId: _createdCampaignId, root: _root, data: bytes32("foo")});
        DistributeRewardsBundle[] memory _distributeRewardBundles = new DistributeRewardsBundle[](1);
        _distributeRewardBundles[0] = _distributeRewardBundle;

        vm.prank(updater);
        metrom.distributeRewards(_distributeRewardBundles);

        vm.assertEq(metrom.campaignById(metrom.campaignId(_createBundle)).root, _root);

        bytes32[] memory _proof = new bytes32[](1);
        _proof[0] = bytes32(0x8d67ceed8123952c42fc6264420185abfbffce5ebebea680b578e3a882e48b85);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: _createdCampaignId,
            proof: _proof,
            token: address(_mintableErc20),
            amount: 90 ether,
            receiver: address(3)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        metrom.recoverRewards(_bundles);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(3)), 90 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(metrom)), 910 ether);

        vm.expectRevert(IMetrom.ZeroAmount.selector);
        metrom.recoverRewards(_bundles);
    }

    function test_success() public {
        vm.etch(address(1234), address(new MintableERC20("Test", "TST")).code);
        MintableERC20 _mintableErc20 = MintableERC20(address(1234));
        _mintableErc20.mint(address(this), 1000 ether);
        _mintableErc20.approve(address(metrom), 1000 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 1000 ether);

        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(_mintableErc20);

        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = 1000 ether;

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
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0 ether);

        bytes32 _createdCampaignId = metrom.campaignId(_createBundle);
        ReadonlyCampaign memory _createdCampaign = metrom.campaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.chainId, _createBundle.chainId);
        vm.assertEq(_createdCampaign.pool, _createBundle.pool);
        vm.assertEq(_createdCampaign.from, _createBundle.from);
        vm.assertEq(_createdCampaign.to, _createBundle.to);
        vm.assertEq(_createdCampaign.specification, _createBundle.specification);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(_createdCampaign.rewards.length, 1);
        vm.assertEq(_createdCampaign.rewards[0].token, address(_mintableErc20));
        vm.assertEq(_createdCampaign.rewards[0].amount, 990 ether);
        vm.assertEq(_createdCampaign.rewards[0].unclaimed, 990 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(metrom)), 1000 ether);

        // the following root is taken by constructing a tree
        // including the following 2 claims:
        // [
        //     {
        //         account: "0x0000000000000000000000000000000000000000",
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

        bytes32 _root = bytes32(0x40e9e0b48e6b5b10bcf2b72e0c7af4fe754c94bb43ef3e668c9fb535bb3554ae);
        DistributeRewardsBundle memory _distributeRewardBundle =
            DistributeRewardsBundle({campaignId: _createdCampaignId, root: _root, data: bytes32("foo")});
        DistributeRewardsBundle[] memory _distributeRewardBundles = new DistributeRewardsBundle[](1);
        _distributeRewardBundles[0] = _distributeRewardBundle;

        vm.prank(updater);
        metrom.distributeRewards(_distributeRewardBundles);

        vm.assertEq(metrom.campaignById(metrom.campaignId(_createBundle)).root, _root);

        bytes32[] memory _proof = new bytes32[](1);
        _proof[0] = bytes32(0x8d67ceed8123952c42fc6264420185abfbffce5ebebea680b578e3a882e48b85);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: _createdCampaignId,
            proof: _proof,
            token: address(_mintableErc20),
            amount: 90 ether,
            receiver: address(3)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        metrom.recoverRewards(_bundles);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(3)), 90 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(metrom)), 910 ether);
    }
}
