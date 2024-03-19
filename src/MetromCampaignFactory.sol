pragma solidity 0.8.25;

import {Clones} from "oz/proxy/Clones.sol";

import {IMetromCampaignFactory} from "./interfaces/IMetromCampaignFactory.sol";
import {IMetromCampaign} from "./interfaces/IMetromCampaign.sol";
import {MAX_FEE} from "./Commons.sol";
import {Reward} from "./Commons.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract MetromCampaignFactory is IMetromCampaignFactory {
    address public override owner;
    address public override pendingOwner;
    address public override updater;
    address public override implementation;
    address public override feeReceiver;
    uint16 public override fee;

    constructor(address _owner, address _updater, address _implementation, address _feeReceiver, uint16 _fee) {
        if (_owner == address(0)) revert InvalidOwner();
        if (_updater == address(0)) revert InvalidUpdater();
        if (_implementation == address(0)) revert InvalidImplementation();
        if (_feeReceiver == address(0)) revert InvalidFeeReceiver();
        if (_fee > MAX_FEE) revert InvalidFee();

        owner = _owner;
        updater = _updater;
        implementation = _implementation;
        feeReceiver = _feeReceiver;
        fee = _fee;

        emit Initialize(_owner, _updater, _implementation, _feeReceiver, _fee);
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

    function create(bytes32 _specificationHash, Reward[] calldata _rewards) external override returns (address) {
        address _instance =
            Clones.cloneDeterministic(implementation, keccak256(abi.encodePacked(msg.sender, _specificationHash)));
        IMetromCampaign(_instance).initialize(msg.sender, _specificationHash, feeReceiver, fee, _rewards);
        emit Create(_instance);
        return _instance;
    }

    function setUpdater(address _updater) external override {
        if (msg.sender != owner) revert Forbidden();
        if (_updater == address(0)) revert InvalidUpdater();
        updater = _updater;
        emit SetUpdater(_updater);
    }

    function setImplementation(address _implementation) external override {
        if (msg.sender != owner) revert Forbidden();
        if (_implementation == address(0)) revert InvalidImplementation();
        implementation = _implementation;
        emit SetImplementation(_implementation);
    }

    function setFeeReceiver(address _feeReceiver) external override {
        if (msg.sender != owner) revert Forbidden();
        if (_feeReceiver == address(0)) revert InvalidFeeReceiver();
        feeReceiver = _feeReceiver;
        emit SetFeeReceiver(_feeReceiver);
    }

    function setFee(uint16 _fee) external override {
        if (msg.sender != owner) revert Forbidden();
        if (_fee > MAX_FEE) revert InvalidFee();
        fee = _fee;
        emit SetFee(_fee);
    }
}
