pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";

import {MintableERC20} from "./dependencies/MintableERC20.sol";
import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {
    IMetrom,
    SetMinimumTokenRateBundle,
    CreateRewardsCampaignBundle,
    CreatePointsCampaignBundle,
    RewardAmount
} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract BaseTest is Test {
    address internal owner;
    address internal updater;
    uint32 internal creationFee;
    uint32 internal reimbursementFee;
    uint32 internal minimumCampaignDuration;
    uint32 internal maximumCampaignDuration;
    MetromHarness internal metrom;

    function setUp() external {
        owner = address(1);
        updater = address(2);
        creationFee = 10_000;
        reimbursementFee = 50_000;
        minimumCampaignDuration = 1 seconds;
        maximumCampaignDuration = 30 minutes;
        metrom = MetromHarness(
            address(
                new ERC1967Proxy(
                    address(new MetromHarness()),
                    abi.encodeWithSelector(
                        IMetrom.initialize.selector,
                        owner,
                        updater,
                        creationFee,
                        reimbursementFee,
                        minimumCampaignDuration,
                        maximumCampaignDuration
                    )
                )
            )
        );
    }

    function createFixedRewardsCampaign() internal returns (bytes32) {
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

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](0);

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundles);

        return metrom.rewardsCampaignId(_createRewardsCampaignBundle);
    }

    function createFixedPointsCampaign() internal returns (bytes32) {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10 ether);
        _mintableErc20.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10 ether);
        setMinimumFeeRate(address(_mintableErc20), 1 ether);

        CreatePointsCampaignBundle memory _createPointsCampaignBundle = CreatePointsCampaignBundle({
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            kind: 1,
            data: abi.encode(address(1)),
            specificationHash: bytes32(0),
            points: 10 ether,
            feeToken: address(_mintableErc20)
        });

        CreateRewardsCampaignBundle[] memory _createRewardsCampaignBundles = new CreateRewardsCampaignBundle[](0);

        CreatePointsCampaignBundle[] memory _createPointsCampaignBundles = new CreatePointsCampaignBundle[](1);
        _createPointsCampaignBundles[0] = _createPointsCampaignBundle;

        metrom.createCampaigns(_createRewardsCampaignBundles, _createPointsCampaignBundles);

        return metrom.pointsCampaignId(_createPointsCampaignBundle);
    }

    // internal utility function to set a given minimum reward rate for a given token,
    // optionally whitelisting it in the process
    function setMinimumRewardRate(address _token, uint256 _newRate) internal {
        SetMinimumTokenRateBundle memory _minimumEmissionBundle =
            SetMinimumTokenRateBundle({token: _token, minimumRate: _newRate});
        SetMinimumTokenRateBundle[] memory _minimumEmissionBundles = new SetMinimumTokenRateBundle[](1);
        _minimumEmissionBundles[0] = _minimumEmissionBundle;

        vm.assertEq(metrom.minimumRewardTokenRate(_token), 0);

        vm.prank(updater);
        metrom.setMinimumTokenRates(_minimumEmissionBundles, new SetMinimumTokenRateBundle[](0));

        vm.assertEq(metrom.minimumRewardTokenRate(_token), _newRate);
    }

    // internal utility function to set a given minimum fee rate for a given token,
    // optionally whitelisting it in the process
    function setMinimumFeeRate(address _token, uint256 _newRate) internal {
        SetMinimumTokenRateBundle memory _minimumFeeRateBundle =
            SetMinimumTokenRateBundle({token: _token, minimumRate: _newRate});
        SetMinimumTokenRateBundle[] memory _minimumFeeRateBundles = new SetMinimumTokenRateBundle[](1);
        _minimumFeeRateBundles[0] = _minimumFeeRateBundle;

        vm.assertEq(metrom.minimumRewardTokenRate(_token), 0);

        vm.prank(updater);
        metrom.setMinimumTokenRates(new SetMinimumTokenRateBundle[](0), _minimumFeeRateBundles);

        vm.assertEq(metrom.minimumFeeTokenRate(_token), _newRate);
    }
}
