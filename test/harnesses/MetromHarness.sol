pragma solidity 0.8.28;

import {RewardsCampaignsV2Utils, RewardsCampaignsV2} from "../../src/libraries/RewardsCampaignsV2Utils.sol";
import {PointsCampaignsV2Utils, PointsCampaignsV2} from "../../src/libraries/PointsCampaignsV2Utils.sol";
import {Metrom} from "../../src/Metrom.sol";
import {CreateRewardsCampaignBundle, CreatePointsCampaignBundle} from "../../src/IMetrom.sol";

contract MetromHarness is Metrom {
    using RewardsCampaignsV2Utils for RewardsCampaignsV2;
    using PointsCampaignsV2Utils for PointsCampaignsV2;

    function rewardsCampaignId(CreateRewardsCampaignBundle memory _bundle) external view returns (bytes32) {
        return RewardsCampaignsV2Utils.generateId(_bundle);
    }

    function pointsCampaignId(CreatePointsCampaignBundle memory _bundle) external view returns (bytes32) {
        return PointsCampaignsV2Utils.generateId(_bundle);
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
