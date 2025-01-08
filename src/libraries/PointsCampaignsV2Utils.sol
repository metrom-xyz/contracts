pragma solidity 0.8.28;

import {IMetrom, PointsCampaignV2, CreatePointsCampaignBundle, ReadonlyPointsCampaign} from "../IMetrom.sol";

/// @notice Holds the created points based campaigns.
struct PointsCampaignsV2 {
    mapping(bytes32 id => PointsCampaignV2) campaigns;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title PointsCampaignsV2Utils
/// @notice Utility functions to be applied to points based campaigns.
/// @author Federico Luzzi - <federico.luzzi@metrom.xyz>
library PointsCampaignsV2Utils {
    /// @notice Given a creation bundle, returns the id of the campaign that would
    /// be created with the bundle if no errors were to be thrown.
    /// @param _bundle The points based campaign creation bundle.
    /// @return The generated campaign id.
    function generateId(CreatePointsCampaignBundle memory _bundle) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                msg.sender,
                _bundle.from,
                _bundle.to,
                _bundle.kind,
                _bundle.data,
                _bundle.specificationHash,
                _bundle.points
            )
        );
    }

    /// @notice Given a campaign id returns a storage pointer to that campaign in the registry.
    /// This function does not check if the referenced pointer has previously been populated or
    /// not.
    /// @param _self The points based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A storage pointer to the campaign with the given id.
    function get(PointsCampaignsV2 storage _self, bytes32 _id) internal view returns (PointsCampaignV2 storage) {
        return _self.campaigns[_id];
    }

    /// @notice Given a campaign creation bundle returns a storage pointer to that campaign in
    /// the registry. This function reverts if the derived campaign pointer has prepopulated data.
    /// @param _self The points based campaigns registry.
    /// @param _bundle The creation bundle.
    /// @return The new campaign id.
    /// @return A storage pointer to the campaign with the given id.
    function getNew(PointsCampaignsV2 storage _self, CreatePointsCampaignBundle memory _bundle)
        internal
        view
        returns (bytes32, PointsCampaignV2 storage)
    {
        bytes32 _id = generateId(_bundle);
        PointsCampaignV2 storage campaign = _self.campaigns[_id];
        if (campaign.from != 0) revert IMetrom.AlreadyExists();
        return (_id, campaign);
    }

    /// @notice Given a campaign id returns a storage pointer to that campaign in the registry.
    /// This function reverts if the given campaign pointer does not have any prepopulated data.
    /// @param _self The points based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A storage pointer to the campaign with the given id.
    function getExisting(PointsCampaignsV2 storage _self, bytes32 _id)
        internal
        view
        returns (PointsCampaignV2 storage)
    {
        PointsCampaignV2 storage campaign = _self.campaigns[_id];
        if (campaign.from == 0) revert IMetrom.NonExistentCampaign();
        return campaign;
    }

    /// @notice Given a campaign id returns a readonly version of it. This function reverts
    /// if the given campaign pointer does not have any prepopulated data.
    /// @param _self The points based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A readonly version of the campaign with the given id.
    function getExistingReadonly(PointsCampaignsV2 storage _self, bytes32 _id)
        internal
        view
        returns (ReadonlyPointsCampaign memory)
    {
        PointsCampaignV2 storage campaign = getExisting(_self, _id);
        return ReadonlyPointsCampaign({
            owner: campaign.owner,
            pendingOwner: campaign.pendingOwner,
            from: campaign.from,
            to: campaign.to,
            kind: campaign.kind,
            data: campaign.data,
            specificationHash: campaign.specificationHash,
            points: campaign.points
        });
    }
}
