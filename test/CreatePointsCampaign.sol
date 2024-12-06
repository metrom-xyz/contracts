pragma solidity 0.8.28;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {
    UNIT,
    IMetrom,
    CreateRewardsCampaignBundle,
    CreatePointsCampaignBundle,
    ReadonlyPointsCampaign,
    RewardAmount
} from "../src/IMetrom.sol";
import {MintableERC20} from "./dependencies/MintableERC20.sol";
import {MintableFeeOnTransferERC20} from "./dependencies/MintableFeeOnTransferERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract CreatePointsCampaignTest is BaseTest {
    function test_successNoBundles() public {
        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](0);
        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](0);
        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundles);
    }

    function test_failZeroAddressPool() public {
        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = CreatePointsCampaignBundle({
            pool: address(0),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            points: 1 ether,
            feeToken: address(1)
        });

        vm.expectRevert(IMetrom.ZeroAddressPool.selector);
        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);
    }

    function test_failStartTimeInThePast() public {
        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = CreatePointsCampaignBundle({
            pool: address(1),
            from: uint32(block.timestamp),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            points: 1 ether,
            feeToken: address(1)
        });

        vm.expectRevert(IMetrom.StartTimeInThePast.selector);
        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);
    }

    function test_failInvalidToBeforeFrom() public {
        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = CreatePointsCampaignBundle({
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 9),
            specification: bytes32(0),
            points: 1 ether,
            feeToken: address(1)
        });

        vm.expectRevert(IMetrom.DurationTooShort.selector);
        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);
    }

    function test_failDurationTooShort() public {
        uint32 _minimumCampaignDuration = 120;
        vm.prank(owner);
        metrom.setMinimumCampaignDuration(_minimumCampaignDuration);
        vm.assertEq(metrom.minimumCampaignDuration(), _minimumCampaignDuration);

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = CreatePointsCampaignBundle({
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + _minimumCampaignDuration - 1),
            specification: bytes32(0),
            points: 1 ether,
            feeToken: address(1)
        });

        vm.expectRevert(IMetrom.DurationTooShort.selector);
        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);
    }

    function test_failDurationTooLong() public {
        uint32 _maximumCampaignDuration = 1 hours;
        vm.prank(owner);
        metrom.setMaximumCampaignDuration(_maximumCampaignDuration);
        vm.assertEq(metrom.maximumCampaignDuration(), _maximumCampaignDuration);

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = CreatePointsCampaignBundle({
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + _maximumCampaignDuration + 1),
            specification: bytes32(0),
            points: 1 ether,
            feeToken: address(1)
        });

        vm.expectRevert(IMetrom.DurationTooLong.selector);
        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);
    }

    function test_failNoPoints() public {
        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = CreatePointsCampaignBundle({
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            points: 0,
            feeToken: address(1)
        });

        vm.expectRevert(IMetrom.NoPoints.selector);
        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);
    }

    function test_failAlreadyExists() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10.1 ether);
        _mintableErc20.approve(address(metrom), 10.1 ether);
        setMinimumFeeRate(address(_mintableErc20), 1);

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = CreatePointsCampaignBundle({
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            points: 10 ether,
            feeToken: address(_mintableErc20)
        });

        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);

        vm.expectRevert(IMetrom.AlreadyExists.selector);
        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);
    }

    function test_failNotWhitelistedFeeToken() public {
        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = CreatePointsCampaignBundle({
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            points: 10 ether,
            feeToken: address(12)
        });

        vm.expectRevert(IMetrom.DisallowedFeeToken.selector);
        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);
    }

    function test_failNotEnoughFees() public {
        vm.prank(owner);
        metrom.setMaximumCampaignDuration(2 hours);
        vm.prank(owner);
        metrom.setMinimumCampaignDuration(1 hours);

        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 0.5 ether);
        _mintableErc20.approve(address(metrom), 0.5 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0.5 ether);

        setMinimumFeeRate(address(_mintableErc20), 1 ether); // 1e18 / hour

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = CreatePointsCampaignBundle({
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + 1 hours),
            specification: bytes32(0),
            points: 10 ether,
            feeToken: address(_mintableErc20)
        });

        vm.expectRevert();
        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);
    }

    function test_failFeeOnTransferZeroAmountAfterFees() public {
        address _feeOnTransferReceiver = address(55555);
        MintableFeeOnTransferERC20 _mintableFeeOnTransferErc20 =
            new MintableFeeOnTransferERC20("Test", "TST", UNIT, _feeOnTransferReceiver);
        _mintableFeeOnTransferErc20.mint(address(this), 0.5 ether);
        _mintableFeeOnTransferErc20.approve(address(metrom), 0.5 ether);
        vm.assertEq(_mintableFeeOnTransferErc20.balanceOf(address(this)), 0.5 ether);
        setMinimumFeeRate(address(_mintableFeeOnTransferErc20), 1 ether);

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = CreatePointsCampaignBundle({
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + 30 minutes),
            specification: bytes32(0),
            points: 10 ether,
            feeToken: address(_mintableFeeOnTransferErc20)
        });

        vm.expectRevert(IMetrom.FeeAmountTooLow.selector);
        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);
    }

    function test_success() public {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 0.5 ether);
        _mintableErc20.approve(address(metrom), 0.5 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0.5 ether);

        setMinimumFeeRate(address(_mintableErc20), 1 ether);

        CreatePointsCampaignBundle memory _createPointsCampaignBundle = CreatePointsCampaignBundle({
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 10 + 30 minutes),
            specification: bytes32(0),
            points: 10 ether,
            feeToken: address(_mintableErc20)
        });
        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = _createPointsCampaignBundle;

        metrom.createCampaigns(new CreateRewardsCampaignBundle[](0), _createPointsCampaignBundles);

        vm.assertEq(_mintableErc20.balanceOf(address(this)), 0);
        vm.assertEq(metrom.claimableFees(address(_mintableErc20)), 0.5 ether);

        bytes32 _createdCampaignId = metrom.pointsCampaignId(_createPointsCampaignBundle);
        ReadonlyPointsCampaign memory _createdCampaign = metrom.pointsCampaignById(_createdCampaignId);

        vm.assertEq(_createdCampaign.pool, _createPointsCampaignBundle.pool);
        vm.assertEq(_createdCampaign.from, _createPointsCampaignBundle.from);
        vm.assertEq(_createdCampaign.to, _createPointsCampaignBundle.to);
        vm.assertEq(_createdCampaign.specification, _createPointsCampaignBundle.specification);
        vm.assertEq(_createdCampaign.points, _createPointsCampaignBundle.points);
    }
}
