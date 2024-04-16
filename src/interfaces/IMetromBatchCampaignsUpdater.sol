pragma solidity >=0.8.0;

struct Update {
    address camapaign;
    bytes32 treeRoot;
    bytes32 dataHash;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
interface IMetromBatchCampaignsUpdater {
    event Initialize(address indexed owner, address indexed updater);
    event BatchUpdate();
    event TransferOwnership(address indexed owner);
    event AcceptOwnership();

    error Forbidden();
    error InvalidOwner();
    error InvalidUpdater();

    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function updater() external view returns (address);

    function transferOwnership(address owner) external;
    function acceptOwnership() external;
    function batchUpdate(Update[] calldata updates) external;
}
