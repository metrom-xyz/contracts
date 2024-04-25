pragma solidity 0.8.25;

import {Metrom} from "../../src/Metrom.sol";
import {Campaign, CreateBundle} from "../../src/IMetrom.sol";

contract MetromHarness is Metrom {
    constructor(
        address _owner,
        address _updater,
        uint32 _fee,
        uint32 _minimumCampaignDuration,
        uint32 _maximumCampaignDuration
    ) Metrom(_owner, _updater, _fee, _minimumCampaignDuration, _maximumCampaignDuration) {}

    function campaignExists(bytes32 _id) external view {
        _getExistingCampaign(_id);
    }

    function campaignId(CreateBundle memory _bundle) external pure returns (bytes32) {
        return _campaignId(_bundle);
    }
}
