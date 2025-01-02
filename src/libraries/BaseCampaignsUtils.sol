pragma solidity 0.8.28;

import {IMetrom} from "../IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title BasesCampaignsUtils
/// @notice Utility functions to be applied to all campaign types.
/// @author Federico Luzzi - <federico.luzzi@metrom.xyz>
library BaseCampaignsUtils {
    /// @notice Validates the base parameters used to create a Metrom campaign.
    /// @param _from The starting timestamp for the campaign.
    /// @param _to The ending timestamp for the campaign.
    /// @param _minimumCampaignDuration The minimum allowed campaign duration.
    /// @param _maximumCampaignDuration The maximum allowed campaign duration.
    /// @return The overall campaign duration.
    function validate(uint32 _from, uint32 _to, uint32 _minimumCampaignDuration, uint32 _maximumCampaignDuration)
        internal
        view
        returns (uint32)
    {
        if (_from <= block.timestamp) revert IMetrom.StartTimeInThePast();
        if (_to < _from + _minimumCampaignDuration) revert IMetrom.DurationTooShort();
        uint32 _duration = _to - _from;
        if (_duration > _maximumCampaignDuration) revert IMetrom.DurationTooLong();

        return _duration;
    }
}
