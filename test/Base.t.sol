pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";

import {MintableERC20} from "./dependencies/MintableERC20.sol";
import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {MAX_FEE, IMetrom, SetMinimumRewardTokenRateBundle, CreateBundle, RewardAmount} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract BaseTest is Test {
    address internal owner;
    address internal updater;
    uint32 internal fee;
    uint32 internal minimumCampaignDuration;
    uint32 internal maximumCampaignDuration;
    MetromHarness internal metrom;

    function setUp() external {
        owner = address(1);
        updater = address(2);
        fee = 10_000;
        minimumCampaignDuration = 1 seconds;
        maximumCampaignDuration = 10 minutes;
        metrom = MetromHarness(
            address(
                new ERC1967Proxy(
                    address(new MetromHarness()),
                    abi.encodeWithSelector(
                        IMetrom.initialize.selector,
                        owner,
                        updater,
                        fee,
                        minimumCampaignDuration,
                        maximumCampaignDuration
                    )
                )
            )
        );
    }

    function createFixedCampaign() internal returns (bytes32) {
        MintableERC20 _mintableErc20 = new MintableERC20("Test", "TST");
        _mintableErc20.mint(address(this), 10 ether);
        _mintableErc20.approve(address(metrom), 10 ether);
        vm.assertEq(_mintableErc20.balanceOf(address(this)), 10 ether);
        setMinimumRewardRate(address(_mintableErc20), 1);

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: address(_mintableErc20), amount: 10 ether});

        CreateBundle memory _createBundle = CreateBundle({
            pool: address(1),
            from: uint32(block.timestamp + 10),
            to: uint32(block.timestamp + 20),
            specification: bytes32(0),
            rewards: _rewards
        });

        CreateBundle[] memory _createBundles = new CreateBundle[](1);
        _createBundles[0] = _createBundle;

        metrom.createCampaigns(_createBundles);

        return metrom.campaignId(_createBundle);
    }

    // internal utility function to set a given minimum reward rate for a given token,
    // optionally whitelisting it in the process
    function setMinimumRewardRate(address _token, uint256 _newRate) internal {
        SetMinimumRewardTokenRateBundle memory _minimumEmissionBundle =
            SetMinimumRewardTokenRateBundle({token: _token, minimumRate: _newRate});
        SetMinimumRewardTokenRateBundle[] memory _minimumEmissionBundles = new SetMinimumRewardTokenRateBundle[](1);
        _minimumEmissionBundles[0] = _minimumEmissionBundle;

        vm.assertEq(metrom.minimumRewardTokenRate(_token), 0);

        vm.prank(updater);
        metrom.setMinimumRewardTokenRates(_minimumEmissionBundles);

        vm.assertEq(metrom.minimumRewardTokenRate(_token), _newRate);
    }
}
