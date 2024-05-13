pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";

import {MintableERC20} from "./dependencies/MintableERC20.sol";
import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom, CreateBundle} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract BaseTest is Test {
    address internal owner;
    address internal updater;
    uint32 internal globalFee;
    uint32 internal minimumCampaignDuration;
    uint32 internal maximumCampaignDuration;
    MetromHarness internal metrom;

    function setUp() external {
        owner = address(1);
        updater = address(2);
        globalFee = 10_000;
        minimumCampaignDuration = 1 seconds;
        maximumCampaignDuration = 10 minutes;
        metrom = new MetromHarness(owner, updater, globalFee, minimumCampaignDuration, maximumCampaignDuration);
    }

    function createFixedCampaign() internal returns (bytes32) {
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

        return metrom.campaignId(_createBundle);
    }
}
