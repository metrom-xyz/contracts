pragma solidity 0.8.25;

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract AcceptCampaignOwnershipTest is BaseTest {
    function test_failNonExistentCampaign() public {
        vm.expectRevert(IMetrom.NonExistentCampaign.selector);
        metrom.acceptCampaignOwnership(bytes32("foo"));
    }

    function test_failForbidden() public {
        bytes32 _campaignId = createFixedCampaign();

        vm.expectRevert(IMetrom.Forbidden.selector);
        metrom.acceptCampaignOwnership(_campaignId);
    }

    function test_success() public {
        bytes32 _campaignId = createFixedCampaign();
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        address _newOwner = address(10001);
        metrom.transferCampaignOwnership(_campaignId, _newOwner);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), _newOwner);
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        vm.expectEmit();
        emit IMetrom.AcceptCampaignOwnership(_campaignId);

        vm.prank(_newOwner);
        metrom.acceptCampaignOwnership(_campaignId);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), address(0));
        vm.assertEq(metrom.campaignOwner(_campaignId), _newOwner);
    }

    function testFuzz_success(address _newOwner) public {
        bytes32 _campaignId = createFixedCampaign();
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        metrom.transferCampaignOwnership(_campaignId, _newOwner);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), _newOwner);
        vm.assertEq(metrom.campaignOwner(_campaignId), address(this));

        vm.expectEmit();
        emit IMetrom.AcceptCampaignOwnership(_campaignId);

        vm.prank(_newOwner);
        metrom.acceptCampaignOwnership(_campaignId);
        vm.assertEq(metrom.campaignPendingOwner(_campaignId), address(0));
        vm.assertEq(metrom.campaignOwner(_campaignId), _newOwner);
    }
}
