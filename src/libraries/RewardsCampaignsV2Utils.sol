pragma solidity 0.8.28;

import {IMetrom, RewardsCampaignV2, CreateRewardsCampaignBundle, ReadonlyRewardsCampaign, Reward} from "../IMetrom.sol";

/// @dev Represents the maximum number of different rewards allowed for a
/// single campaign.
uint256 constant MAX_REWARDS_PER_CAMPAIGN = 5;

/// @notice Holds the created points based campaigns.
struct RewardsCampaignsV2 {
    mapping(bytes32 id => RewardsCampaignV2) campaigns;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title RewardsCampaignsV2Utils
/// @notice Utility functions to be applied to points based campaigns.
/// @author Federico Luzzi - <federico.luzzi@metrom.xyz>
library RewardsCampaignsV2Utils {
    /// @notice Given a creation bundle, returns the id of the campaign that would
    /// be created with the bundle if no errors were to be thrown.
    /// @param _bundle The points based campaign creation bundle.
    /// @return The generated campaign id.
    function generateId(CreateRewardsCampaignBundle memory _bundle) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                msg.sender,
                _bundle.from,
                _bundle.to,
                _bundle.kind,
                _bundle.data,
                _bundle.specificationHash,
                _bundle.rewards
            )
        );
    }

    /// @notice Given a campaign id returns a storage pointer to that campaign in the registry.
    /// This function does not check if the referenced pointer has previously been populated or
    /// not.
    /// @param _self The points based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A storage pointer to the campaign with the given id.
    function get(RewardsCampaignsV2 storage _self, bytes32 _id) internal view returns (RewardsCampaignV2 storage) {
        return _self.campaigns[_id];
    }

    /// @notice Given a campaign creation bundle returns a storage pointer to that campaign in
    /// the registry. This function reverts if the derived campaign pointer has prepopulated data.
    /// @param _self The points based campaigns registry.
    /// @param _bundle The creation bundle.
    /// @return The new campaign id.
    /// @return A storage pointer to the campaign with the given id.
    function getNew(RewardsCampaignsV2 storage _self, CreateRewardsCampaignBundle memory _bundle)
        internal
        view
        returns (bytes32, RewardsCampaignV2 storage)
    {
        bytes32 _id = generateId(_bundle);
        RewardsCampaignV2 storage campaign = _self.campaigns[_id];
        if (campaign.from != 0) revert IMetrom.AlreadyExists();
        return (_id, campaign);
    }

    /// @notice Given a campaign id returns a storage pointer to that campaign in the registry.
    /// This function reverts if the given campaign pointer does not have any prepopulated data.
    /// @param _self The points based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A storage pointer to the campaign with the given id.
    function getExisting(RewardsCampaignsV2 storage _self, bytes32 _id)
        internal
        view
        returns (RewardsCampaignV2 storage)
    {
        RewardsCampaignV2 storage campaign = _self.campaigns[_id];
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
    function getRewardOnExistingCampaign(RewardsCampaignsV2 storage _self, bytes32 _id, address _token)
        internal
        view
        returns (Reward storage)
    {
        return getExisting(_self, _id).reward[_token];
    }

    /// @notice Given a campaign id returns a readonly version of it. This function reverts
    /// if the given campaign pointer does not have any prepopulated data.
    /// @param _self The points based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A readonly version of the campaign with the given id.
    function getExistingReadonly(RewardsCampaignsV2 storage _self, bytes32 _id)
        internal
        view
        returns (ReadonlyRewardsCampaign memory)
    {
        RewardsCampaignV2 storage campaign = getExisting(_self, _id);
        return ReadonlyRewardsCampaign({
            owner: campaign.owner,
            pendingOwner: campaign.pendingOwner,
            from: campaign.from,
            to: campaign.to,
            kind: campaign.kind,
            data: campaign.data,
            specificationHash: campaign.specificationHash,
            root: campaign.root,
            dataHash: campaign.dataHash
        });
    }
}
