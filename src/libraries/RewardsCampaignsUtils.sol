pragma solidity 0.8.28;

import {BaseCampaignsUtils} from "./BaseCampaignsUtils.sol";
import {
    IMetrom,
    RewardsCampaign,
    CreateRewardsCampaignBundle,
    ReadonlyRewardsCampaign,
    CreateRewardsCampaignBundle,
    Reward
} from "../IMetrom.sol";

/// @dev Represents the maximum number of different rewards allowed for a
/// single campaign.
uint256 constant MAX_REWARDS_PER_CAMPAIGN = 5;

/// @notice Holds the created rewards based campaigns.
struct RewardsCampaigns {
    mapping(bytes32 id => RewardsCampaign) campaigns;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title RewardsCampaignsUtils
/// @notice Utility functions to be applied to rewards based campaigns.
/// @author Federico Luzzi - <federico.luzzi@metrom.xyz>
library RewardsCampaignsUtils {
    /// @notice Given a creation bundle, returns the id of the campaign that would
    /// be created with the bundle if no errors were to be thrown.
    /// @param _bundle The rewards based campaign creation bundle.
    /// @return The generated campaign id.
    function generateId(CreateRewardsCampaignBundle memory _bundle) internal view returns (bytes32) {
        return keccak256(abi.encode(msg.sender, _bundle));
    }

    /// @notice Given a campaign id returns a storage pointer to that campaign in the registry.
    /// This function does not check if the referenced pointer has previously been populated or
    /// not.
    /// @param _self The rewards based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A storage pointer to the campaign with the given id.
    function get(RewardsCampaigns storage _self, bytes32 _id) internal view returns (RewardsCampaign storage) {
        return _self.campaigns[_id];
    }

    /// @notice Given a campaign creation bundle returns a storage pointer to that campaign in
    /// the registry. This function reverts if the derived campaign pointer has prepopulated data.
    /// @param _self The rewards based campaigns registry.
    /// @param _bundle The creation bundle.
    /// @return The new campaign id.
    /// @return A storage pointer to the campaign with the given id.
    function getNew(RewardsCampaigns storage _self, CreateRewardsCampaignBundle memory _bundle)
        internal
        view
        returns (bytes32, RewardsCampaign storage)
    {
        bytes32 _id = generateId(_bundle);
        RewardsCampaign storage campaign = _self.campaigns[_id];
        if (campaign.owner != address(0)) revert IMetrom.AlreadyExists();
        return (_id, campaign);
    }

    /// @notice Given a campaign id returns a storage pointer to that campaign in the registry.
    /// This function reverts if the given campaign pointer does not have any prepopulated data.
    /// @param _self The rewards based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A storage pointer to the campaign with the given id.
    function getExisting(RewardsCampaigns storage _self, bytes32 _id) internal view returns (RewardsCampaign storage) {
        RewardsCampaign storage campaign = _self.campaigns[_id];
        if (campaign.owner == address(0)) revert IMetrom.NonExistentCampaign();
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
    function getRewardOnExistingCampaign(RewardsCampaigns storage _self, bytes32 _id, address _token)
        internal
        view
        returns (Reward storage)
    {
        return getExisting(_self, _id).reward[_token];
    }

    /// @notice Given a campaign id returns a readonly version of it. This function reverts
    /// if the given campaign pointer does not have any prepopulated data.
    /// @param _self The rewards based campaigns registry.
    /// @param _id The id of the targeted campaign.
    /// @return A readonly version of the campaign with the given id.
    function getExistingReadonly(RewardsCampaigns storage _self, bytes32 _id)
        internal
        view
        returns (ReadonlyRewardsCampaign memory)
    {
        RewardsCampaign storage campaign = getExisting(_self, _id);
        return ReadonlyRewardsCampaign({
            owner: campaign.owner,
            pendingOwner: campaign.pendingOwner,
            from: campaign.from,
            to: campaign.to,
            specification: campaign.specification,
            root: campaign.root,
            data: campaign.data
        });
    }
}
