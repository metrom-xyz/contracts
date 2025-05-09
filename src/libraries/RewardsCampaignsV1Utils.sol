pragma solidity 0.8.30;

import {BaseCampaignsUtils} from "./BaseCampaignsUtils.sol";
import {IMetrom, RewardsCampaignV1, ReadonlyRewardsCampaign, Reward} from "../IMetrom.sol";

/// @notice Holds the created rewards based campaigns.
struct RewardsCampaignsV1 {
    mapping(bytes32 id => RewardsCampaignV1) campaigns;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title RewardsCampaignsV1Utils
/// @notice Utility functions to be applied to rewards based campaigns.
/// @author Federico Luzzi - <federico.luzzi@metrom.xyz>
library RewardsCampaignsV1Utils {
    /// @notice Given a campaign id returns a storage pointer to that campaign in the registry.
    /// This function does not check if the referenced pointer has previously been populated or
    /// not.
    /// @param _self The rewards based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A storage pointer to the campaign with the given id.
    function get(RewardsCampaignsV1 storage _self, bytes32 _id) internal view returns (RewardsCampaignV1 storage) {
        return _self.campaigns[_id];
    }

    /// @notice Given a campaign id returns a storage pointer to that campaign in the registry.
    /// This function reverts if the given campaign pointer does not have any prepopulated data.
    /// @param _self The rewards based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A storage pointer to the campaign with the given id.
    function getExisting(RewardsCampaignsV1 storage _self, bytes32 _id)
        internal
        view
        returns (RewardsCampaignV1 storage)
    {
        RewardsCampaignV1 storage campaign = _self.campaigns[_id];
        if (campaign.from == 0) revert IMetrom.NonExistentCampaign();
        return campaign;
    }

    /// @notice Given a campaign id and a token address returns a storage pointer to the reward
    /// linked to the campaign with the given id and with the given token address. This function
    /// reverts if no campaign with the given id has been created.
    /// @param _self The rewards based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @param _token The token address of the targeted reward.
    /// @return A storage pointer to the reward with the given token address for the campaign with
    /// the given id.
    function getRewardOnExistingCampaign(RewardsCampaignsV1 storage _self, bytes32 _id, address _token)
        internal
        view
        returns (Reward storage)
    {
        return getExisting(_self, _id).reward[_token];
    }
}
