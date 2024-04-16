pragma solidity 0.8.25;

import {IMetromBatchCampaignsUpdater, Update} from "./interfaces/IMetromBatchCampaignsUpdater.sol";
import {IMetromCampaign} from "./interfaces/IMetromCampaign.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract MetromBatchCampaignsUpdater is IMetromBatchCampaignsUpdater {
    address public override owner;
    address public override pendingOwner;
    address public override updater;

    constructor(address _owner, address _updater) {
        if (_owner == address(0)) revert InvalidOwner();
        if (_updater == address(0)) revert InvalidUpdater();

        owner = _owner;
        updater = _updater;

        emit Initialize(_owner, _updater);
    }

    function transferOwnership(address _owner) external {
        if (msg.sender != owner) revert Forbidden();
        pendingOwner = _owner;
        emit TransferOwnership(_owner);
    }

    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert Forbidden();
        delete pendingOwner;
        owner = msg.sender;
        emit AcceptOwnership();
    }

    function batchUpdate(Update[] calldata _updates) external override {
        if (msg.sender != updater) revert Forbidden();
        for (uint256 _i; _i < _updates.length; _i++) {
            Update calldata _update = _updates[_i];
            IMetromCampaign(_update.camapaign).updateTree(_update.treeRoot, _update.dataHash);
        }
        emit BatchUpdate();
    }
}
