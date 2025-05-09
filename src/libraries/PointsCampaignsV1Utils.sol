pragma solidity 0.8.30;

import {IMetrom, PointsCampaignV1, ReadonlyPointsCampaign} from "../IMetrom.sol";

/// @notice Holds the created points based campaigns.
struct PointsCampaignsV1 {
    mapping(bytes32 id => PointsCampaignV1) campaigns;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title PointsCampaignsV1Utils
/// @notice Utility functions to be applied to points based campaigns.
/// @author Federico Luzzi - <federico.luzzi@metrom.xyz>
library PointsCampaignsV1Utils {
    /// @notice Given a campaign id returns a storage pointer to that campaign in the registry.
    /// This function does not check if the referenced pointer has previously been populated or
    /// not.
    /// @param _self The points based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A storage pointer to the campaign with the given id.
    function get(PointsCampaignsV1 storage _self, bytes32 _id) internal view returns (PointsCampaignV1 storage) {
        return _self.campaigns[_id];
    }

    /// @notice Given a campaign id returns a storage pointer to that campaign in the registry.
    /// This function reverts if the given campaign pointer does not have any prepopulated data.
    /// @param _self The points based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A storage pointer to the campaign with the given id.
    function getExisting(PointsCampaignsV1 storage _self, bytes32 _id)
        internal
        view
        returns (PointsCampaignV1 storage)
    {
        PointsCampaignV1 storage campaign = _self.campaigns[_id];
        if (campaign.from == 0) revert IMetrom.NonExistentCampaign();
        return campaign;
    }
}
