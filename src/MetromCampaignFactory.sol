pragma solidity 0.8.25;

import {Clones} from "oz/proxy/Clones.sol";

import {IMetromCampaignFactory, CreateCampaignParams} from "./interfaces/IMetromCampaignFactory.sol";
import {IMetromCampaign, InitializeCampaignParams} from "./interfaces/IMetromCampaign.sol";
import {MAX_FEE, TokenAmount} from "./Commons.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract MetromCampaignFactory is IMetromCampaignFactory {
    address public override owner;
    address public override pendingOwner;
    address public override updater;
    address public override implementation;
    address public override feeReceiver;
    uint32 public override fee;

    constructor(address _owner, address _updater, address _implementation, address _feeReceiver, uint32 _fee) {
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

    function create(CreateCampaignParams calldata _params) external override returns (address) {
        uint256 _rewardsLength = _params.rewards.length;
        address[] memory _rewardTokens = new address[](_rewardsLength);
        uint256[] memory _rewardAmounts = new uint256[](_rewardsLength);
        for (uint256 _i = 0; _i < _params.rewards.length; _i++) {
            _rewardTokens[_i] = _params.rewards[_i].token;
            _rewardAmounts[_i] = _params.rewards[_i].amount;
        }
        address _instance = Clones.cloneDeterministic(
            implementation,
            keccak256(
                abi.encodePacked(msg.sender, _params.pool, _params.from, _params.to, _rewardTokens, _rewardAmounts)
            )
        );
        emit Create(_instance);
        IMetromCampaign(_instance).initialize(
            InitializeCampaignParams({
                owner: msg.sender,
                feeReceiver: feeReceiver,
                fee: fee,
                pool: _params.pool,
                from: _params.from,
                to: _params.to,
                rewards: _params.rewards
            })
        );
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

    function setFee(uint32 _fee) external override {
        if (msg.sender != owner) revert Forbidden();
        if (_fee > MAX_FEE) revert InvalidFee();
        fee = _fee;
        emit SetFee(_fee);
    }
}
