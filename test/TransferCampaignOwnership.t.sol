pragma solidity 0.8.30;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract TransferCampaignOwnershipTest is BaseTest {
    function test_failNonExistentCampaign() public {
        vm.expectRevert(IMetrom.NonExistentCampaign.selector);
        metrom.transferCampaignOwnership(bytes32("foo"), address(10));
    }

    function test_failZeroAddressOwnerRewardsCampaign() public {
        bytes32 _campaignId = createFixedRewardsCampaign();

        vm.expectRevert(IMetrom.ZeroAddressOwner.selector);
        metrom.transferCampaignOwnership(_campaignId, address(0));
    }

    function test_failZeroAddressOwnerPointsCampaign() public {
        bytes32 _campaignId = createFixedPointsCampaign();

        vm.expectRevert(IMetrom.ZeroAddressOwner.selector);
        metrom.transferCampaignOwnership(_campaignId, address(0));
    }

    function test_failForbiddenRewardsCampaign() public {
        bytes32 _campaignId = createFixedRewardsCampaign();

        vm.expectRevert(IMetrom.Forbidden.selector);
        vm.prank(address(1234));
        metrom.transferCampaignOwnership(_campaignId, address(10));
    }

    function test_failForbiddenPointsCampaign() public {
        bytes32 _campaignId = createFixedPointsCampaign();

        vm.expectRevert(IMetrom.Forbidden.selector);
        vm.prank(address(1234));
        metrom.transferCampaignOwnership(_campaignId, address(10));
    }

    function test_successRewardsCampaign() public {
        bytes32 _campaignId = createFixedRewardsCampaign();

        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        address _newOwner = address(10001);

        vm.expectEmit();
        emit IMetrom.TransferCampaignOwnership(_campaignId, _newOwner);

        metrom.transferCampaignOwnership(_campaignId, _newOwner);

        vm.assertEq(metrom.campaignPendingOwner(_campaignId), _newOwner);
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));
    }

    function test_successPointsCampaign() public {
        bytes32 _campaignId = createFixedPointsCampaign();

        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        address _newOwner = address(10001);

        vm.expectEmit();
        emit IMetrom.TransferCampaignOwnership(_campaignId, _newOwner);

        metrom.transferCampaignOwnership(_campaignId, _newOwner);

        vm.assertEq(metrom.campaignPendingOwner(_campaignId), _newOwner);
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));
    }

    function testFuzz_successRewardsCampaign(address _newOwner) public {
        vm.assume(_newOwner != address(0));

        bytes32 _campaignId = createFixedRewardsCampaign();

        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        vm.expectEmit();
        emit IMetrom.TransferCampaignOwnership(_campaignId, _newOwner);

        metrom.transferCampaignOwnership(_campaignId, _newOwner);

        vm.assertEq(metrom.campaignPendingOwner(_campaignId), _newOwner);
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));
    }

    function testFuzz_successPointsCampaign(address _newOwner) public {
        vm.assume(_newOwner != address(0));

        bytes32 _campaignId = createFixedPointsCampaign();

        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        vm.expectEmit();
        emit IMetrom.TransferCampaignOwnership(_campaignId, _newOwner);

        metrom.transferCampaignOwnership(_campaignId, _newOwner);

        vm.assertEq(metrom.campaignPendingOwner(_campaignId), _newOwner);
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));
    }
}
