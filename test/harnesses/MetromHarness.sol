pragma solidity 0.8.25;

import {Metrom} from "../../src/Metrom.sol";
import {Campaign, CreateBundle} from "../../src/IMetrom.sol";

contract MetromHarness is Metrom {
    function campaignExists(bytes32 _id) external view {
        _getExistingCampaign(_id);
    }

    function campaignId(CreateBundle memory _bundle) external view returns (bytes32) {
        return _campaignId(_bundle);
    }

    function resolvedFee() external view returns (uint32) {
        return _resolvedFee();
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
