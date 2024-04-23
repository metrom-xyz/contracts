pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom, CreateBundle, ClaimRewardBundle, ReadonlyCampaign} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract DistributeRewardsTest is BaseTest {
    function test_successNoBundles() public {
        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](0);
        metrom.claimRewards(_bundles);
    }

    function test_FailInvalidRoot() public {
        bytes32[] memory _proof = new bytes32[](0);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: bytes32(0),
            proof: _proof,
            token: address(0),
            amount: 10 ether,
            receiver: address(0)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidToken.selector);
        metrom.claimRewards(_bundles);
    }

    function test_failZeroAmount() public {
        bytes32[] memory _proof = new bytes32[](0);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: bytes32(0),
            proof: _proof,
            token: address(1),
            amount: 0 ether,
            receiver: address(0)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.ZeroAmount.selector);
        metrom.claimRewards(_bundles);
    }

    function test_failNonExistentCampaign() public {
        bytes32[] memory _proof = new bytes32[](0);

        ClaimRewardBundle memory _bundle = ClaimRewardBundle({
            campaignId: bytes32(0),
            proof: _proof,
            token: address(1),
            amount: 1 ether,
            receiver: address(0)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.NonExistentCampaign.selector);
        metrom.claimRewards(_bundles);
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
            receiver: address(0)
        });

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidProof.selector);
        metrom.claimRewards(_bundles);
    }

    // TODO: implement tests for success scenarios
}
