pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom, CreateBundle, ReadonlyCampaign} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract CreateCampaignTest is BaseTest {
    function test_CceateCampaignSuccessNoBundles() public {
        CreateBundle[] memory _bundles = new CreateBundle[](0);
        metrom.createCampaigns(_bundles);
    }

    function test_createCampaignFailInvalidPool() public {
        address[] memory _rewardTokens = new address[](0);
        uint256[] memory _rewardAmounts = new uint256[](0);

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(0),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidPool.selector);
        metrom.createCampaigns(_bundles);
    }

    function test_createCampaignFailInvalidFrom() public {
        address[] memory _rewardTokens = new address[](0);
        uint256[] memory _rewardAmounts = new uint256[](0);

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidFrom.selector);
        metrom.createCampaigns(_bundles);
    }

    function test_createCampaignFailInvalidToBeforeFrom() public {
        address[] memory _rewardTokens = new address[](0);
        uint256[] memory _rewardAmounts = new uint256[](0);

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 9),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidTo.selector);
        metrom.createCampaigns(_bundles);
    }

    function test_createCampaignFailInvalidToBeforeMinimumCampaignDuration() public {
        uint32 _minimumCampaignDuration = 120;
        vm.prank(owner);
        metrom.setMinimumCampaignDuration(_minimumCampaignDuration);
        vm.assertEq(metrom.minimumCampaignDuration(), _minimumCampaignDuration);

        address[] memory _rewardTokens = new address[](0);
        uint256[] memory _rewardAmounts = new uint256[](0);

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + _minimumCampaignDuration - 1),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidTo.selector);
        metrom.createCampaigns(_bundles);
    }

    function test_createCampaignFailNoRewards() public {
        address[] memory _rewardTokens = new address[](0);
        uint256[] memory _rewardAmounts = new uint256[](0);

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidRewards.selector);
        metrom.createCampaigns(_bundles);
    }

    function test_createCampaignFailTooManyRewards() public {
        address[] memory _rewardTokens = new address[](6);
        uint256[] memory _rewardAmounts = new uint256[](0);

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidRewards.selector);
        metrom.createCampaigns(_bundles);
    }

    function test_createCampaignFailInconsistentTokensAndAmounts() public {
        address[] memory _rewardTokens = new address[](3);
        uint256[] memory _rewardAmounts = new uint256[](1);

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidRewards.selector);
        metrom.createCampaigns(_bundles);
    }

    function test_createCampaignFailAlreadyExists() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10.1 ether);
        _mintableErc20.approve(address(metrom), 10.1 ether);

        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(_mintableErc20);

        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = 10 ether;

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        metrom.createCampaigns(_bundles);

        vm.expectRevert(IMetrom.CampaignAlreadyExists.selector);
        metrom.createCampaigns(_bundles);
    }

    function test_createCampaignFailZeroRewardAmount() public {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(1);

        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = 0;

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidRewards.selector);
        metrom.createCampaigns(_bundles);
    }

    function test_createCampaignFailDuplicatedRewardToken() public {
        address[] memory _rewardTokens = new address[](2);
        _rewardTokens[0] = address(1);
        _rewardTokens[1] = address(1);

        uint256[] memory _rewardAmounts = new uint256[](2);
        _rewardAmounts[0] = 10;
        _rewardAmounts[1] = 20;

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectRevert(IMetrom.InvalidRewards.selector);
        metrom.createCampaigns(_bundles);
    }

    function test_createCampaignSuccessSingleSingleReward() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10.1 ether);
        _mintableErc20.approve(address(metrom), 10.1 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10.1 ether);

        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(_mintableErc20);

        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = 10 ether;

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.CreateCampaign(
            address(this),
            _bundle.pool,
            _bundle.from,
            _bundle.to,
            _bundle.specification,
            _bundle.rewardTokens,
            _bundle.rewardAmounts
        );
        metrom.createCampaigns(_bundles);

        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);
        vm.assertEq(metrom.accruedFees(address(_mintableErc20)), 0.1 ether);

        bytes32 _createdCampaignId = metrom.campaignId(_bundle);
        ReadonlyCampaign memory _createdCampaign = metrom.campaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.chainId, _bundle.chainId);
        vm.assertEq(_createdCampaign.pool, _bundle.pool);
        vm.assertEq(_createdCampaign.from, _bundle.from);
        vm.assertEq(_createdCampaign.to, _bundle.to);
        vm.assertEq(_createdCampaign.specification, _bundle.specification);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(_createdCampaign.rewards.length, 1);
        vm.assertEq(_createdCampaign.rewards[0].token, address(_mintableErc20));
        vm.assertEq(_createdCampaign.rewards[0].amount, 10 ether);
        vm.assertEq(_createdCampaign.rewards[0].unclaimed, 10 ether);
    }

    function test_createCampaignSuccessMultipleSingleReward() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 15.15 ether);
        _mintableErc20.approve(address(metrom), 15.15 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 15.15 ether);

        address[] memory _rewardTokens1 = new address[](1);
        _rewardTokens1[0] = address(_mintableErc20);

        uint256[] memory _rewardAmounts1 = new uint256[](1);
        _rewardAmounts1[0] = 10 ether;

        CreateBundle memory _bundle1 = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens1,
            rewardAmounts: _rewardAmounts1
        });

        address[] memory _rewardTokens2 = new address[](1);
        _rewardTokens2[0] = address(_mintableErc20);

        uint256[] memory _rewardAmounts2 = new uint256[](1);
        _rewardAmounts2[0] = 5 ether;

        CreateBundle memory _bundle2 = CreateBundle({
            chainId: 2,
            pool: address(2),
            from: uint32(block.timestamp + 100),
            to: uint32(block.timestamp + 1020),
            specification: bytes32("test-spec"),
            rewardTokens: _rewardTokens2,
            rewardAmounts: _rewardAmounts2
        });

        CreateBundle[] memory _bundles = new CreateBundle[](2);
        _bundles[0] = _bundle1;
        _bundles[1] = _bundle2;

        vm.expectEmit();
        emit IMetrom.CreateCampaign(
            address(this),
            _bundle1.pool,
            _bundle1.from,
            _bundle1.to,
            _bundle1.specification,
            _bundle1.rewardTokens,
            _bundle1.rewardAmounts
        );
        emit IMetrom.CreateCampaign(
            address(this),
            _bundle2.pool,
            _bundle2.from,
            _bundle2.to,
            _bundle2.specification,
            _bundle2.rewardTokens,
            _bundle2.rewardAmounts
        );
        metrom.createCampaigns(_bundles);

        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);
        vm.assertEq(metrom.accruedFees(address(_mintableErc20)), 0.15 ether);

        bytes32 _createdCampaignId1 = metrom.campaignId(_bundle1);
        ReadonlyCampaign memory _createdCampaign1 = metrom.campaignById(_createdCampaignId1);

        vm.assertEq(_createdCampaign1.chainId, _bundle1.chainId);
        vm.assertEq(_createdCampaign1.pool, _bundle1.pool);
        vm.assertEq(_createdCampaign1.from, _bundle1.from);
        vm.assertEq(_createdCampaign1.to, _bundle1.to);
        vm.assertEq(_createdCampaign1.specification, _bundle1.specification);
        vm.assertEq(_createdCampaign1.root, bytes32(0));
        vm.assertEq(_createdCampaign1.rewards.length, 1);
        vm.assertEq(_createdCampaign1.rewards[0].token, address(_mintableErc20));
        vm.assertEq(_createdCampaign1.rewards[0].amount, 10 ether);
        vm.assertEq(_createdCampaign1.rewards[0].unclaimed, 10 ether);

        bytes32 _createdCampaignId2 = metrom.campaignId(_bundle2);
        ReadonlyCampaign memory _createdCampaign2 = metrom.campaignById(_createdCampaignId2);

        vm.assertEq(_createdCampaign2.chainId, _bundle2.chainId);
        vm.assertEq(_createdCampaign2.pool, _bundle2.pool);
        vm.assertEq(_createdCampaign2.from, _bundle2.from);
        vm.assertEq(_createdCampaign2.to, _bundle2.to);
        vm.assertEq(_createdCampaign2.specification, _bundle2.specification);
        vm.assertEq(_createdCampaign2.root, bytes32(0));
        vm.assertEq(_createdCampaign2.rewards.length, 1);
        vm.assertEq(_createdCampaign2.rewards[0].token, address(_mintableErc20));
        vm.assertEq(_createdCampaign2.rewards[0].amount, 5 ether);
        vm.assertEq(_createdCampaign2.rewards[0].unclaimed, 5 ether);
    }

    function test_createCampaignSuccessSingleMultipleeward() public {
        MintableERC20 _mintableErc201 = new MintableERC20("Test 1", "TST1");
        _mintableErc201.mint(address(this), 10.1 ether);
        _mintableErc201.approve(address(metrom), 10.1 ether);
        vm.assertEq(_mintableErc201.balanceOf(address(this)), 10.1 ether);

        MintableERC20 _mintableErc202 = new MintableERC20("Test 2", "TST2");
        _mintableErc202.mint(address(this), 5.05 ether);
        _mintableErc202.approve(address(metrom), 5.05 ether);
        vm.assertEq(_mintableErc202.balanceOf(address(this)), 5.05 ether);

        address[] memory _rewardTokens = new address[](2);
        _rewardTokens[0] = address(_mintableErc201);
        _rewardTokens[1] = address(_mintableErc202);

        uint256[] memory _rewardAmounts = new uint256[](2);
        _rewardAmounts[0] = 10 ether;
        _rewardAmounts[1] = 5 ether;

        CreateBundle memory _bundle = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens,
            rewardAmounts: _rewardAmounts
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        vm.expectEmit();
        emit IMetrom.CreateCampaign(
            address(this),
            _bundle.pool,
            _bundle.from,
            _bundle.to,
            _bundle.specification,
            _bundle.rewardTokens,
            _bundle.rewardAmounts
        );
        metrom.createCampaigns(_bundles);

        vm.assertEq(_mintableErc201.balanceOf(address(this)), 0);
        vm.assertEq(metrom.accruedFees(address(_mintableErc201)), 0.1 ether);

        vm.assertEq(_mintableErc202.balanceOf(address(this)), 0);
        vm.assertEq(metrom.accruedFees(address(_mintableErc202)), 0.05 ether);

        bytes32 _createdCampaignId = metrom.campaignId(_bundle);
        ReadonlyCampaign memory _createdCampaign = metrom.campaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.chainId, _bundle.chainId);
        vm.assertEq(_createdCampaign.pool, _bundle.pool);
        vm.assertEq(_createdCampaign.from, _bundle.from);
        vm.assertEq(_createdCampaign.to, _bundle.to);
        vm.assertEq(_createdCampaign.specification, _bundle.specification);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(_createdCampaign.rewards.length, 2);
        vm.assertEq(_createdCampaign.rewards[0].token, address(_mintableErc201));
        vm.assertEq(_createdCampaign.rewards[0].amount, 10 ether);
        vm.assertEq(_createdCampaign.rewards[0].unclaimed, 10 ether);
        vm.assertEq(_createdCampaign.rewards[1].token, address(_mintableErc202));
        vm.assertEq(_createdCampaign.rewards[1].amount, 5 ether);
        vm.assertEq(_createdCampaign.rewards[1].unclaimed, 5 ether);
    }

    function test_createCampaignSuccessMultipleMultipleReward() public {
        MintableERC20 _mintableErc201 = new MintableERC20("Test", "TST");
        _mintableErc201.mint(address(this), 15.15 ether);
        _mintableErc201.approve(address(metrom), 15.15 ether);
        vm.assertEq(_mintableErc201.balanceOf(address(this)), 15.15 ether);

        MintableERC20 _mintableErc202 = new MintableERC20("Test", "TST");
        _mintableErc202.mint(address(this), 10.1 ether);
        _mintableErc202.approve(address(metrom), 10.1 ether);
        vm.assertEq(_mintableErc202.balanceOf(address(this)), 10.1 ether);

        address[] memory _rewardTokens1 = new address[](2);
        _rewardTokens1[0] = address(_mintableErc201);
        _rewardTokens1[1] = address(_mintableErc202);

        uint256[] memory _rewardAmounts1 = new uint256[](2);
        _rewardAmounts1[0] = 10 ether;
        _rewardAmounts1[1] = 5 ether;

        CreateBundle memory _bundle1 = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens1,
            rewardAmounts: _rewardAmounts1
        });

        address[] memory _rewardTokens2 = new address[](2);
        _rewardTokens2[0] = address(_mintableErc201);
        _rewardTokens2[1] = address(_mintableErc202);

        uint256[] memory _rewardAmounts2 = new uint256[](2);
        _rewardAmounts2[0] = 5 ether;
        _rewardAmounts2[1] = 5 ether;

        CreateBundle memory _bundle2 = CreateBundle({
            chainId: 1,
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewardTokens: _rewardTokens2,
            rewardAmounts: _rewardAmounts2
        });

        CreateBundle[] memory _bundles = new CreateBundle[](2);
        _bundles[0] = _bundle1;
        _bundles[1] = _bundle2;

        vm.expectEmit();
        emit IMetrom.CreateCampaign(
            address(this),
            _bundle1.pool,
            _bundle1.from,
            _bundle1.to,
            _bundle1.specification,
            _bundle1.rewardTokens,
            _bundle1.rewardAmounts
        );
        emit IMetrom.CreateCampaign(
            address(this),
            _bundle2.pool,
            _bundle2.from,
            _bundle2.to,
            _bundle2.specification,
            _bundle2.rewardTokens,
            _bundle2.rewardAmounts
        );
        metrom.createCampaigns(_bundles);

        vm.assertEq(_mintableErc201.balanceOf(address(this)), 0);
        vm.assertEq(metrom.accruedFees(address(_mintableErc201)), 0.15 ether);

        vm.assertEq(_mintableErc202.balanceOf(address(this)), 0);
        vm.assertEq(metrom.accruedFees(address(_mintableErc202)), 0.1 ether);

        bytes32 _createdCampaignId1 = metrom.campaignId(_bundle1);
        ReadonlyCampaign memory _createdCampaign1 = metrom.campaignById(_createdCampaignId1);

        vm.assertEq(_createdCampaign1.chainId, _bundle1.chainId);
        vm.assertEq(_createdCampaign1.pool, _bundle1.pool);
        vm.assertEq(_createdCampaign1.from, _bundle1.from);
        vm.assertEq(_createdCampaign1.to, _bundle1.to);
        vm.assertEq(_createdCampaign1.specification, _bundle1.specification);
        vm.assertEq(_createdCampaign1.root, bytes32(0));
        vm.assertEq(_createdCampaign1.rewards.length, 2);
        vm.assertEq(_createdCampaign1.rewards[0].token, address(_mintableErc201));
        vm.assertEq(_createdCampaign1.rewards[0].amount, 10 ether);
        vm.assertEq(_createdCampaign1.rewards[0].unclaimed, 10 ether);
        vm.assertEq(_createdCampaign1.rewards[1].token, address(_mintableErc202));
        vm.assertEq(_createdCampaign1.rewards[1].amount, 5 ether);
        vm.assertEq(_createdCampaign1.rewards[1].unclaimed, 5 ether);

        bytes32 _createdCampaignId2 = metrom.campaignId(_bundle2);
        ReadonlyCampaign memory _createdCampaign2 = metrom.campaignById(_createdCampaignId2);

        vm.assertEq(_createdCampaign2.chainId, _bundle2.chainId);
        vm.assertEq(_createdCampaign2.pool, _bundle2.pool);
        vm.assertEq(_createdCampaign2.from, _bundle2.from);
        vm.assertEq(_createdCampaign2.to, _bundle2.to);
        vm.assertEq(_createdCampaign2.specification, _bundle2.specification);
        vm.assertEq(_createdCampaign2.root, bytes32(0));
        vm.assertEq(_createdCampaign2.rewards.length, 2);
        vm.assertEq(_createdCampaign2.rewards[0].token, address(_mintableErc201));
        vm.assertEq(_createdCampaign2.rewards[0].amount, 5 ether);
        vm.assertEq(_createdCampaign2.rewards[0].unclaimed, 5 ether);
        vm.assertEq(_createdCampaign2.rewards[1].token, address(_mintableErc202));
        vm.assertEq(_createdCampaign2.rewards[1].amount, 5 ether);
        vm.assertEq(_createdCampaign2.rewards[1].unclaimed, 5 ether);
    }
}
