pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE, UNIT, IMetrom, CreateBundle, ReadonlyCampaign} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract CreateCampaignTest is BaseTest {
    function test_successNoBundles() public {
        CreateBundle[] memory _bundles = new CreateBundle[](0);
        metrom.createCampaigns(_bundles);
    }

    function test_failInvalidPool() public {
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

    function test_failInvalidFrom() public {
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

    function test_failInvalidToBeforeFrom() public {
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

    function test_failInvalidToBeforeMinimumCampaignDuration() public {
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

    function test_failNoRewards() public {
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

    function test_failTooManyRewards() public {
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

    function test_failInconsistentTokensAndAmounts() public {
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

    function test_failAlreadyExists() public {
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

    function test_failZeroRewardAmount() public {
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

    function test_failZeroAddressRewardToken() public {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = address(0);

        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = 10;

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

    function test_successSingleDuplicatedReward() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 25 ether);
        _mintableErc20.approve(address(metrom), 25 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 25 ether);

        address[] memory _rewardTokens = new address[](2);
        _rewardTokens[0] = address(_mintableErc20);
        _rewardTokens[1] = address(_mintableErc20);

        uint256[] memory _rewardAmounts = new uint256[](2);
        _rewardAmounts[0] = 10 ether;
        _rewardAmounts[1] = 15 ether;

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

        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0.25 ether);

        bytes32 _createdCampaignId = metrom.campaignId(_bundle);
        ReadonlyCampaign memory _createdCampaign = metrom.campaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.chainId, _bundle.chainId);
        vm.assertEq(_createdCampaign.pool, _bundle.pool);
        vm.assertEq(_createdCampaign.from, _bundle.from);
        vm.assertEq(_createdCampaign.to, _bundle.to);
        vm.assertEq(_createdCampaign.specification, _bundle.specification);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableErc20)), 24.75 ether);
    }

    function test_successSingleSingleReward() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10 ether);
        _mintableErc20.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10 ether);

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

        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0.1 ether);

        bytes32 _createdCampaignId = metrom.campaignId(_bundle);
        ReadonlyCampaign memory _createdCampaign = metrom.campaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.chainId, _bundle.chainId);
        vm.assertEq(_createdCampaign.pool, _bundle.pool);
        vm.assertEq(_createdCampaign.from, _bundle.from);
        vm.assertEq(_createdCampaign.to, _bundle.to);
        vm.assertEq(_createdCampaign.specification, _bundle.specification);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableErc20)), 9.9 ether);
    }

    function test_successSingleSingleRewardFeeRebate() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10 ether);
        _mintableErc20.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10 ether);

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

        vm.prank(owner);
        metrom.setFeeRebate(address(this), UNIT);

        metrom.createCampaigns(_bundles);

        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0 ether);

        bytes32 _createdCampaignId = metrom.campaignId(_bundle);
        ReadonlyCampaign memory _createdCampaign = metrom.campaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.chainId, _bundle.chainId);
        vm.assertEq(_createdCampaign.pool, _bundle.pool);
        vm.assertEq(_createdCampaign.from, _bundle.from);
        vm.assertEq(_createdCampaign.to, _bundle.to);
        vm.assertEq(_createdCampaign.specification, _bundle.specification);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableErc20)), 10 ether);
    }

    function test_successMultipleSingleReward() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 15 ether);
        _mintableErc20.approve(address(metrom), 15 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 15 ether);

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
            to: uint32(block.timestamp + 120),
            specification: bytes32("test-spec"),
            rewardTokens: _rewardTokens2,
            rewardAmounts: _rewardAmounts2
        });

        CreateBundle[] memory _bundles = new CreateBundle[](2);
        _bundles[0] = _bundle1;
        _bundles[1] = _bundle2;

        metrom.createCampaigns(_bundles);

        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0.15 ether);

        {
            bytes32 _createdCampaignId1 = metrom.campaignId(_bundle1);
            ReadonlyCampaign memory _createdCampaign1 = metrom.campaignById(_createdCampaignId1);

            vm.assertEq(_createdCampaign1.chainId, _bundle1.chainId);
            vm.assertEq(_createdCampaign1.pool, _bundle1.pool);
            vm.assertEq(_createdCampaign1.from, _bundle1.from);
            vm.assertEq(_createdCampaign1.to, _bundle1.to);
            vm.assertEq(_createdCampaign1.specification, _bundle1.specification);
            vm.assertEq(_createdCampaign1.root, bytes32(0));
            vm.assertEq(metrom.campaignReward(_createdCampaignId1, address(_mintableErc20)), 9.9 ether);
        }

        {
            bytes32 _createdCampaignId2 = metrom.campaignId(_bundle2);
            ReadonlyCampaign memory _createdCampaign2 = metrom.campaignById(_createdCampaignId2);

            vm.assertEq(_createdCampaign2.chainId, _bundle2.chainId);
            vm.assertEq(_createdCampaign2.pool, _bundle2.pool);
            vm.assertEq(_createdCampaign2.from, _bundle2.from);
            vm.assertEq(_createdCampaign2.to, _bundle2.to);
            vm.assertEq(_createdCampaign2.specification, _bundle2.specification);
            vm.assertEq(_createdCampaign2.root, bytes32(0));
            vm.assertEq(metrom.campaignReward(_createdCampaignId2, address(_mintableErc20)), 4.95 ether);
        }
    }

    function test_successSingleMultipleReward() public {
        MintableERC20 _mintableErc201 = new MintableERC20("Test 1", "TST1");
        _mintableErc201.mint(address(this), 10 ether);
        _mintableErc201.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc201.balanceOf(address(this)), 10 ether);

        MintableERC20 _mintableErc202 = new MintableERC20("Test 2", "TST2");
        _mintableErc202.mint(address(this), 5 ether);
        _mintableErc202.approve(address(metrom), 5 ether);
        vm.assertEq(_mintableErc202.balanceOf(address(this)), 5 ether);

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

        metrom.createCampaigns(_bundles);

        vm.assertEq(_mintableErc201.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc201)), 0.1 ether);

        vm.assertEq(_mintableErc202.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc202)), 0.05 ether);

        bytes32 _createdCampaignId = metrom.campaignId(_bundle);
        ReadonlyCampaign memory _createdCampaign = metrom.campaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.chainId, _bundle.chainId);
        vm.assertEq(_createdCampaign.pool, _bundle.pool);
        vm.assertEq(_createdCampaign.from, _bundle.from);
        vm.assertEq(_createdCampaign.to, _bundle.to);
        vm.assertEq(_createdCampaign.specification, _bundle.specification);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableErc201)), 9.9 ether);
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableErc202)), 4.95 ether);
    }

    function test_successMultipleMultipleReward() public {
        MintableERC20 _mintableErc201 = new MintableERC20("Test", "TST");
        _mintableErc201.mint(address(this), 15 ether);
        _mintableErc201.approve(address(metrom), 15 ether);
        vm.assertEq(_mintableErc201.balanceOf(address(this)), 15 ether);

        MintableERC20 _mintableErc202 = new MintableERC20("Test", "TST");
        _mintableErc202.mint(address(this), 10 ether);
        _mintableErc202.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc202.balanceOf(address(this)), 10 ether);

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

        metrom.createCampaigns(_bundles);

        vm.assertEq(_mintableErc201.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc201)), 0.15 ether);

        vm.assertEq(_mintableErc202.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc202)), 0.1 ether);

        {
            bytes32 _createdCampaignId1 = metrom.campaignId(_bundle1);
            ReadonlyCampaign memory _createdCampaign1 = metrom.campaignById(_createdCampaignId1);

            vm.assertEq(_createdCampaign1.chainId, _bundle1.chainId);
            vm.assertEq(_createdCampaign1.pool, _bundle1.pool);
            vm.assertEq(_createdCampaign1.from, _bundle1.from);
            vm.assertEq(_createdCampaign1.to, _bundle1.to);
            vm.assertEq(_createdCampaign1.specification, _bundle1.specification);
            vm.assertEq(_createdCampaign1.root, bytes32(0));
            vm.assertEq(metrom.campaignReward(_createdCampaignId1, address(_mintableErc201)), 9.9 ether);
            vm.assertEq(metrom.campaignReward(_createdCampaignId1, address(_mintableErc202)), 4.95 ether);
        }

        {
            bytes32 _createdCampaignId2 = metrom.campaignId(_bundle2);
            ReadonlyCampaign memory _createdCampaign2 = metrom.campaignById(_createdCampaignId2);

            vm.assertEq(_createdCampaign2.chainId, _bundle2.chainId);
            vm.assertEq(_createdCampaign2.pool, _bundle2.pool);
            vm.assertEq(_createdCampaign2.from, _bundle2.from);
            vm.assertEq(_createdCampaign2.to, _bundle2.to);
            vm.assertEq(_createdCampaign2.specification, _bundle2.specification);
            vm.assertEq(_createdCampaign2.root, bytes32(0));
            vm.assertEq(metrom.campaignReward(_createdCampaignId2, address(_mintableErc201)), 4.95 ether);
            vm.assertEq(metrom.campaignReward(_createdCampaignId2, address(_mintableErc202)), 4.95 ether);
        }
    }
}
