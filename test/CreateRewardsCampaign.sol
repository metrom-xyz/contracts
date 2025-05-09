pragma solidity 0.8.28;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {
    UNIT,
    IMetrom,
    CreateRewardsCampaignBundle,
    CreatePointsCampaignBundle,
    ReadonlyRewardsCampaign,
    RewardAmount
} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";
import {MintableFeeOnTransferERC20} from "./dependencies/MintableFeeOnTransferERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract CreateRewardsCampaignTest is BaseTest {
    function test_successNoBundles() public {
        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](0);
        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](0);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundles);
    }

    function test_failStartTimeInThePast() public {
        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp),
            to: uint32(block.timestamp + 20),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: new RewardAmount[](0)
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.StartTimeInThePast.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundles);
    }

    function test_failInvalidToBeforeFrom() public {
        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 9),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: new RewardAmount[](0)
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.DurationTooShort.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundles);
    }

    function test_failDurationTooShort() public {
        uint32 _minimumCampaignDuration = 120;
        vm.prank(owner);
        metrom.setMinimumCampaignDuration(_minimumCampaignDuration);
        vm.assertEq(metrom.minimumCampaignDuration(), _minimumCampaignDuration);

        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + _minimumCampaignDuration - 1),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: new RewardAmount[](0)
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.DurationTooShort.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_failDurationTooLong() public {
        uint32 _maximumCampaignDuration = 1 hours;
        vm.prank(owner);
        metrom.setMaximumCampaignDuration(_maximumCampaignDuration);
        vm.assertEq(metrom.maximumCampaignDuration(), _maximumCampaignDuration);

        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + _maximumCampaignDuration + 1),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: new RewardAmount[](0)
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.DurationTooLong.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_failNoRewards() public {
        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: new RewardAmount[](0)
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.NoRewards.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_failTooManyRewards() public {
        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: new RewardAmount[](6)
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.TooManyRewards.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_failAlreadyExists() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10.1 ether);
        _mintableErc20.approve(address(metrom), 10.1 ether);
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

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);

        vm.expectRevert(IMetrom.AlreadyExists.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_failZeroRewardAmount() public {
        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(1), amount: 0});

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

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.ZeroRewardAmount.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_failZeroAddressRewardToken() public {
        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(0), amount: 10});

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

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.ZeroAddressRewardToken.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_failEoaAddressRewardToken() public {
        setMinimumRewardRate(address(18266661), 1);

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), amount: 10});

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

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert();
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_failNotWhitelistedToken() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 25 ether);
        _mintableErc20.approve(address(metrom), 25 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 25 ether);

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(_mintableErc20), amount: 25 ether});

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

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.DisallowedRewardToken.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_failNotEnoughRewardsSingle() public {
        vm.prank(owner);
        metrom.setMaximumCampaignDuration(2 hours);
        vm.prank(owner);
        metrom.setMinimumCampaignDuration(1 hours);

        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 25 ether);
        _mintableErc20.approve(address(metrom), 25 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 25 ether);

        setMinimumRewardRate(address(_mintableErc20), 10 ether); // 10e18 / hour

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(_mintableErc20), amount: 5 ether});

        // creating a campaign lasting 1 hour with 5e18 reward tokens, which
        // is less than the minimum rate
        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + 1 hours),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: _rewards
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.RewardAmountTooLow.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_failNotEnoughRewardsMultiple() public {
        vm.prank(owner);
        metrom.setMaximumCampaignDuration(2 hours);
        vm.prank(owner);
        metrom.setMinimumCampaignDuration(1 hours);

        MintableERC20 _mintableErc201 = new MintableERC20("Test1", "TST1");
        _mintableErc201.mint(address(this), 10 ether);
        _mintableErc201.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc201.balanceOf(address(this)), 10 ether);
        setMinimumRewardRate(address(_mintableErc201), 10 ether); // 10e18 / hour

        MintableERC20 _mintableErc202 = new MintableERC20("Test2", "TST2");
        _mintableErc202.mint(address(this), 18 ether);
        _mintableErc202.approve(address(metrom), 18 ether);
        vm.assertEq(_mintableErc202.balanceOf(address(this)), 18 ether);
        setMinimumRewardRate(address(_mintableErc202), 20 ether); // 20e18 / hour

        RewardAmount[] memory _rewards = new RewardAmount[](2);
        _rewards[0] = RewardAmount({token: address(_mintableErc201), amount: 10 ether});
        _rewards[1] = RewardAmount({token: address(_mintableErc202), amount: 18 ether});

        // creating a campaign lasting 1 hour with 10 reward tokens 1 (respecting the
        // minimum rate) and 18 reward tokens 2 (less than the minimum rate of 20/hr)
        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + 1 hours),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: _rewards
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.RewardAmountTooLow.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_failNotEnoughRewardsShortCampaign() public {
        vm.prank(owner);
        metrom.setMaximumCampaignDuration(1 hours);
        vm.prank(owner);
        metrom.setMinimumCampaignDuration(15 minutes);

        MintableERC20 _mintableErc20 = new MintableERC20("Test1", "TST1");
        _mintableErc20.mint(address(this), 10 ether);
        _mintableErc20.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10 ether);
        setMinimumRewardRate(address(_mintableErc20), 1 ether); // 1e18 / hour

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(_mintableErc20), amount: 0.245 ether});

        // creating a campaign lasting 1 hour with 0.24 reward tokens 1
        // (less than the minimum rate of 1/hr)
        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + 1 hours),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: _rewards
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.RewardAmountTooLow.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_successEnoughRewardsShortCampaign() public {
        vm.prank(owner);
        metrom.setMaximumCampaignDuration(1 hours);
        vm.prank(owner);
        metrom.setMinimumCampaignDuration(15 minutes);

        MintableERC20 _mintableErc20 = new MintableERC20("Test1", "TST1");
        _mintableErc20.mint(address(this), 0.25 ether);
        _mintableErc20.approve(address(metrom), 0.25 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0.25 ether);
        setMinimumRewardRate(address(_mintableErc20), 1 ether); // 1e18 / hour

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(_mintableErc20), amount: 0.25 ether});

        // creating a campaign lasting 15 minutes with 0.25 reward tokens 1
        // (enough to respect the minimum rate of 1/hr)
        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + 15 minutes),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: _rewards
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](1);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);

        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0.0025 ether);

        bytes32 _createdCampaignId = metrom.rewardsCampaignId(_createRewardsCampaignBundle);
        ReadonlyRewardsCampaign memory _createdCampaign = metrom.rewardsCampaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.from, _createRewardsCampaignBundle.from);
        vm.assertEq(_createdCampaign.to, _createRewardsCampaignBundle.to);
        vm.assertEq(_createdCampaign.kind, _createRewardsCampaignBundle.kind);
        vm.assertEq(_createdCampaign.data, _createRewardsCampaignBundle.data);
        vm.assertEq(_createdCampaign.specificationHash, _createRewardsCampaignBundle.specificationHash);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableErc20)), 0.2475 ether);
    }

    function test_failFeeOnTransferZeroAmountAfterFees() public {
        address _feeOnTransferReceiver = address(55555);
        MintableFeeOnTransferERC20 _mintableFeeOnTransferErc20 =
            new MintableFeeOnTransferERC20("Test", "TST", UNIT, _feeOnTransferReceiver);
        _mintableFeeOnTransferErc20.mint(address(this), 10 ether);
        _mintableFeeOnTransferErc20.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableFeeOnTransferErc20.balanceOf(address(this)), 10 ether);
        setMinimumRewardRate(address(_mintableFeeOnTransferErc20), 1);

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(_mintableFeeOnTransferErc20), amount: 10 ether});

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

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        vm.expectRevert(IMetrom.ZeroRewardAmount.selector);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);
    }

    function test_successSingleRewardFeeOnTransfer() public {
        address _feeOnTransferReceiver = address(55555);
        MintableFeeOnTransferERC20 _mintableFeeOnTransferErc20 =
            new MintableFeeOnTransferERC20("Test", "TST", 100_000, _feeOnTransferReceiver);
        _mintableFeeOnTransferErc20.mint(address(this), 10 ether);
        _mintableFeeOnTransferErc20.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableFeeOnTransferErc20.balanceOf(address(this)), 10 ether);
        setMinimumRewardRate(address(_mintableFeeOnTransferErc20), 1);

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(_mintableFeeOnTransferErc20), amount: 10 ether});

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

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);

        vm.assertEq(_mintableFeeOnTransferErc20.balanceOf(address(this)), 0);
        vm.assertEq(_mintableFeeOnTransferErc20.balanceOf(_feeOnTransferReceiver), 1 ether);
        vm.assertEq(metrom.claimableFees(address(_mintableFeeOnTransferErc20)), 0.09 ether);

        bytes32 _createdCampaignId = metrom.rewardsCampaignId(_createRewardsCampaignBundle);
        ReadonlyRewardsCampaign memory _createdCampaign = metrom.rewardsCampaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.from, _createRewardsCampaignBundle.from);
        vm.assertEq(_createdCampaign.to, _createRewardsCampaignBundle.to);
        vm.assertEq(_createdCampaign.kind, _createRewardsCampaignBundle.kind);
        vm.assertEq(_createdCampaign.data, _createRewardsCampaignBundle.data);
        vm.assertEq(_createdCampaign.specificationHash, _createRewardsCampaignBundle.specificationHash);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableFeeOnTransferErc20)), 8.91 ether);
    }

    function test_successSingleSingleReward() public {
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

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);

        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0.1 ether);

        bytes32 _createdCampaignId = metrom.rewardsCampaignId(_createRewardsCampaignBundle);
        ReadonlyRewardsCampaign memory _createdCampaign = metrom.rewardsCampaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.from, _createRewardsCampaignBundle.from);
        vm.assertEq(_createdCampaign.to, _createRewardsCampaignBundle.to);
        vm.assertEq(_createdCampaign.kind, _createRewardsCampaignBundle.kind);
        vm.assertEq(_createdCampaign.data, _createRewardsCampaignBundle.data);
        vm.assertEq(_createdCampaign.specificationHash, _createRewardsCampaignBundle.specificationHash);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableErc20)), 9.9 ether);
    }

    function test_successSingleSingleRewardFeeRebate() public {
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

        vm.prank(owner);
        metrom.setCreationFeeRebate(address(this), UNIT);

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);

        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0 ether);

        bytes32 _createdCampaignId = metrom.rewardsCampaignId(_createRewardsCampaignBundle);
        ReadonlyRewardsCampaign memory _createdCampaign = metrom.rewardsCampaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.from, _createRewardsCampaignBundle.from);
        vm.assertEq(_createdCampaign.to, _createRewardsCampaignBundle.to);
        vm.assertEq(_createdCampaign.kind, _createRewardsCampaignBundle.kind);
        vm.assertEq(_createdCampaign.data, _createRewardsCampaignBundle.data);
        vm.assertEq(_createdCampaign.specificationHash, _createRewardsCampaignBundle.specificationHash);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableErc20)), 10 ether);
    }

    function test_successMultipleSingleReward() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 15 ether);
        _mintableErc20.approve(address(metrom), 15 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 15 ether);

        setMinimumRewardRate(address(_mintableErc20), 1);

        RewardAmount[] memory _rewards1 = new RewardAmount[](1);
        _rewards1[0] = RewardAmount({token: address(_mintableErc20), amount: 10 ether});

        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle1 = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: _rewards1
        });

        RewardAmount[] memory _rewards2 = new RewardAmount[](1);
        _rewards2[0] = RewardAmount({token: address(_mintableErc20), amount: 5 ether});

        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle2 = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 100),
            to: uint32(block.timestamp + 120),
            kind: 1,
            data: abi.encode(address(2)),
            specificationHash: bytes32("test-spec"),
            rewards: _rewards2
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](2);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle1;
        _createRewardsCampaignBundles[1] = _createRewardsCampaignBundle2;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);

        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0.15 ether);

        {
            bytes32 _createdCampaignId1 = metrom.rewardsCampaignId(_createRewardsCampaignBundle1);
            ReadonlyRewardsCampaign memory _createdCampaign1 = metrom.rewardsCampaignById(_createdCampaignId1);

            vm.assertEq(_createdCampaign1.from, _createRewardsCampaignBundle1.from);
            vm.assertEq(_createdCampaign1.to, _createRewardsCampaignBundle1.to);
            vm.assertEq(_createdCampaign1.kind, _createRewardsCampaignBundle1.kind);
            vm.assertEq(_createdCampaign1.data, _createRewardsCampaignBundle1.data);
            vm.assertEq(_createdCampaign1.specificationHash, _createRewardsCampaignBundle1.specificationHash);
            vm.assertEq(_createdCampaign1.root, bytes32(0));
            vm.assertEq(metrom.campaignReward(_createdCampaignId1, address(_mintableErc20)), 9.9 ether);
        }

        {
            bytes32 _createdCampaignId2 = metrom.rewardsCampaignId(_createRewardsCampaignBundle2);
            ReadonlyRewardsCampaign memory _createdCampaign2 = metrom.rewardsCampaignById(_createdCampaignId2);

            vm.assertEq(_createdCampaign2.from, _createRewardsCampaignBundle2.from);
            vm.assertEq(_createdCampaign2.to, _createRewardsCampaignBundle2.to);
            vm.assertEq(_createdCampaign2.kind, _createRewardsCampaignBundle2.kind);
            vm.assertEq(_createdCampaign2.data, _createRewardsCampaignBundle2.data);
            vm.assertEq(_createdCampaign2.specificationHash, _createRewardsCampaignBundle2.specificationHash);
            vm.assertEq(_createdCampaign2.root, bytes32(0));
            vm.assertEq(metrom.campaignReward(_createdCampaignId2, address(_mintableErc20)), 4.95 ether);
        }
    }

    function test_successSingleMultipleReward() public {
        MintableERC20 _mintableErc201 = new MintableERC20("Test 1", "TST1");
        _mintableErc201.mint(address(this), 10 ether);
        _mintableErc201.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc201.balanceOf(address(this)), 10 ether);
        setMinimumRewardRate(address(_mintableErc201), 1);

        MintableERC20 _mintableErc202 = new MintableERC20("Test 2", "TST2");
        _mintableErc202.mint(address(this), 5 ether);
        _mintableErc202.approve(address(metrom), 5 ether);
        vm.assertEq(_mintableErc202.balanceOf(address(this)), 5 ether);
        setMinimumRewardRate(address(_mintableErc202), 1);

        RewardAmount[] memory _rewards = new RewardAmount[](2);
        _rewards[0] = RewardAmount({token: address(_mintableErc201), amount: 10 ether});
        _rewards[1] = RewardAmount({token: address(_mintableErc202), amount: 5 ether});

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

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);

        vm.assertEq(_mintableErc201.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc201)), 0.1 ether);

        vm.assertEq(_mintableErc202.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc202)), 0.05 ether);

        bytes32 _createdCampaignId = metrom.rewardsCampaignId(_createRewardsCampaignBundle);
        ReadonlyRewardsCampaign memory _createdCampaign = metrom.rewardsCampaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.from, _createRewardsCampaignBundle.from);
        vm.assertEq(_createdCampaign.to, _createRewardsCampaignBundle.to);
        vm.assertEq(_createdCampaign.kind, _createRewardsCampaignBundle.kind);
        vm.assertEq(_createdCampaign.data, _createRewardsCampaignBundle.data);
        vm.assertEq(_createdCampaign.specificationHash, _createRewardsCampaignBundle.specificationHash);
        vm.assertEq(_createdCampaign.root, bytes32(0));
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableErc201)), 9.9 ether);
        vm.assertEq(metrom.campaignReward(_createdCampaignId, address(_mintableErc202)), 4.95 ether);
    }

    function test_successMultipleMultipleReward() public {
        MintableERC20 _mintableErc201 = new MintableERC20("Test", "TST");
        _mintableErc201.mint(address(this), 15 ether);
        _mintableErc201.approve(address(metrom), 15 ether);
        vm.assertEq(_mintableErc201.balanceOf(address(this)), 15 ether);
        setMinimumRewardRate(address(_mintableErc201), 1);

        MintableERC20 _mintableErc202 = new MintableERC20("Test", "TST");
        _mintableErc202.mint(address(this), 10 ether);
        _mintableErc202.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc202.balanceOf(address(this)), 10 ether);
        setMinimumRewardRate(address(_mintableErc202), 1);

        RewardAmount[] memory _rewards = new RewardAmount[](2);
        _rewards[0] = RewardAmount({token: address(_mintableErc201), amount: 10 ether});
        _rewards[1] = RewardAmount({token: address(_mintableErc202), amount: 5 ether});

        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle1 = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: _rewards
        });

        _rewards = new RewardAmount[](2);
        _rewards[0] = RewardAmount({token: address(_mintableErc201), amount: 5 ether});
        _rewards[1] = RewardAmount({token: address(_mintableErc202), amount: 5 ether});

        CreateRewardsCampaignBundle memory _createRewardsCampaignBundle2 = CreateRewardsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            rewards: _rewards
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](2);
        _createRewardsCampaignBundles[0] = _createRewardsCampaignBundle1;
        _createRewardsCampaignBundles[1] = _createRewardsCampaignBundle2;

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundless = new CreatePointsCampaignBundle[](0);

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundless);

        vm.assertEq(_mintableErc201.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc201)), 0.15 ether);

        vm.assertEq(_mintableErc202.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc202)), 0.1 ether);

        {
            bytes32 _createdCampaignId1 = metrom.rewardsCampaignId(_createRewardsCampaignBundle1);
            ReadonlyRewardsCampaign memory _createdCampaign1 = metrom.rewardsCampaignById(_createdCampaignId1);

            vm.assertEq(_createdCampaign1.from, _createRewardsCampaignBundle1.from);
            vm.assertEq(_createdCampaign1.to, _createRewardsCampaignBundle1.to);
            vm.assertEq(_createdCampaign1.kind, _createRewardsCampaignBundle1.kind);
            vm.assertEq(_createdCampaign1.data, _createRewardsCampaignBundle1.data);
            vm.assertEq(_createdCampaign1.specificationHash, _createRewardsCampaignBundle1.specificationHash);
            vm.assertEq(_createdCampaign1.root, bytes32(0));
            vm.assertEq(metrom.campaignReward(_createdCampaignId1, address(_mintableErc201)), 9.9 ether);
            vm.assertEq(metrom.campaignReward(_createdCampaignId1, address(_mintableErc202)), 4.95 ether);
        }

        {
            bytes32 _createdCampaignId2 = metrom.rewardsCampaignId(_createRewardsCampaignBundle2);
            ReadonlyRewardsCampaign memory _createdCampaign2 = metrom.rewardsCampaignById(_createdCampaignId2);

            vm.assertEq(_createdCampaign2.from, _createRewardsCampaignBundle2.from);
            vm.assertEq(_createdCampaign2.to, _createRewardsCampaignBundle2.to);
            vm.assertEq(_createdCampaign2.kind, _createRewardsCampaignBundle2.kind);
            vm.assertEq(_createdCampaign2.data, _createRewardsCampaignBundle2.data);
            vm.assertEq(_createdCampaign2.specificationHash, _createRewardsCampaignBundle2.specificationHash);
            vm.assertEq(_createdCampaign2.root, bytes32(0));
            vm.assertEq(metrom.campaignReward(_createdCampaignId2, address(_mintableErc201)), 4.95 ether);
            vm.assertEq(metrom.campaignReward(_createdCampaignId2, address(_mintableErc202)), 4.95 ether);
        }
    }
}
