pragma solidity 0.8.30;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract AcceptCampaignOwnershipTest is BaseTest {
    function test_failNonExistentCampaign() public {
        vm.expectRevert(IMetrom.NonExistentCampaign.selector);
        metrom.acceptCampaignOwnership(bytes32("foo"));
    }

    function test_failForbiddenRewardsCampaign() public {
        bytes32 _campaignId = createFixedRewardsCampaign();

        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.acceptCampaignOwnership(_campaignId);
    }

    function test_failForbiddenPointsCampaign() public {
        bytes32 _campaignId = createFixedPointsCampaign();

        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.acceptCampaignOwnership(_campaignId);
    }

    function test_successRewardsCampaign() public {
        bytes32 _campaignId = createFixedRewardsCampaign();
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        address _newOwner = address(10001);
        metrom.transferCampaignOwnership(_campaignId, _newOwner);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), _newOwner);
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        vm.expectEmit();
        emit IMetrom.AcceptCampaignOwnership(_campaignId, _newOwner);

        vm.prank(_newOwner);
        metrom.acceptCampaignOwnership(_campaignId);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), address(0));
        vm.assertEq(metrom.campaignOwner(_campaignId), _newOwner);
    }

    function test_successPointsCampaign() public {
        bytes32 _campaignId = createFixedPointsCampaign();
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        address _newOwner = address(10001);
        metrom.transferCampaignOwnership(_campaignId, _newOwner);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), _newOwner);
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        vm.expectEmit();
        emit IMetrom.AcceptCampaignOwnership(_campaignId, _newOwner);

        vm.prank(_newOwner);
        metrom.acceptCampaignOwnership(_campaignId);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), address(0));
        vm.assertEq(metrom.campaignOwner(_campaignId), _newOwner);
    }

    function testFuzz_successRewardsCampaign(address _newOwner) public {
        vm.assume(_newOwner != address(0));

        bytes32 _campaignId = createFixedRewardsCampaign();
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        metrom.transferCampaignOwnership(_campaignId, _newOwner);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), _newOwner);
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        vm.expectEmit();
        emit IMetrom.AcceptCampaignOwnership(_campaignId, _newOwner);

        vm.prank(_newOwner);
        metrom.acceptCampaignOwnership(_campaignId);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), address(0));
        vm.assertEq(metrom.campaignOwner(_campaignId), _newOwner);
    }

    function testFuzz_successPointsCampaign(address _newOwner) public {
        vm.assume(_newOwner != address(0));

        bytes32 _campaignId = createFixedPointsCampaign();
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        metrom.transferCampaignOwnership(_campaignId, _newOwner);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), _newOwner);
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        vm.expectEmit();
        emit IMetrom.AcceptCampaignOwnership(_campaignId, _newOwner);

        vm.prank(_newOwner);
        metrom.acceptCampaignOwnership(_campaignId);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), address(0));
        vm.assertEq(metrom.campaignOwner(_campaignId), _newOwner);
    }
}
