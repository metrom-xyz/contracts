pragma solidity >=0.8.0;

import {RewardWithFee, MerkleTree, Reward} from "../Commons.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
interface IMetromCampaignFactory {
    error InvalidOwner();
    error InvalidUpdater();
    error InvalidImplementation();
    error InvalidFeeReceiver();
    error InvalidFee();
    error Forbidden();

    event Initialize(address owner, address updater, address implementation, address feeReceiver, uint16 fee);
    event TransferOwnership(address owner);
    event AcceptOwnership();
    event Create(address campaign);
    event SetUpdater(address updater);
    event SetImplementation(address implementation);
    event SetFeeReceiver(address feeReceiver);
    event SetFee(uint16 fee);

    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function updater() external view returns (address);
    function implementation() external view returns (address);
    function feeReceiver() external view returns (address);
    function fee() external view returns (uint16);

    function transferOwnership(address owner) external;
    function acceptOwnership() external;
    function create(bytes32 specificationHash, Reward[] calldata rewards) external returns (address);
    function setUpdater(address updater) external;
    function setImplementation(address implementation) external;
    function setFeeReceiver(address feeReceiver) external;
    function setFee(uint16 fee) external;
}
