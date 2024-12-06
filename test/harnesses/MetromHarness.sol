pragma solidity 0.8.28;

import {RewardsCampaignsUtils, RewardsCampaigns} from "../../src/libraries/RewardsCampaignsUtils.sol";
import {PointsCampaignsUtils, PointsCampaigns} from "../../src/libraries/PointsCampaignsUtils.sol";
import {Metrom} from "../../src/Metrom.sol";
import {CreateRewardsCampaignBundle, CreatePointsCampaignBundle, RewardsCampaign} from "../../src/IMetrom.sol";

contract MetromHarness is Metrom {
    using RewardsCampaignsUtils for RewardsCampaigns;
    using PointsCampaignsUtils for PointsCampaigns;

    function campaignExists(bytes32 _id) external view {
        RewardsCampaign storage campaign = rewardsCampaigns.get(_id);
        if (campaign.owner == address(0)) pointsCampaigns.getExisting(_id);
    }

    function campaignRewardExists(bytes32 _id, address _token) external view {
        rewardsCampaigns.getRewardOnExistingCampaign(_id, _token).amount != 0;
    }

    function rewardsCampaignId(CreateRewardsCampaignBundle memory _bundle) external view returns (bytes32) {
        return RewardsCampaignsUtils.generateId(_bundle);
    }

    function pointsCampaignId(CreatePointsCampaignBundle memory _bundle) external view returns (bytes32) {
        return PointsCampaignsUtils.generateId(_bundle);
    }

    function resolvedRewardsCampaignFee() external view returns (uint32) {
        return _resolvedRewardsCampaignFee();
    }
}

contract MetromHarnessUpgraded is MetromHarness {
    function upgraded() external pure returns (bool) {
        return true;
    }
}

contract MetromHarnessUpgradedReinitializer is MetromHarness {
    string public value;

    function reinitialize(string calldata _value) external reinitializer(2) {
        value = _value;
    }
}
