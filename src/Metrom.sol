pragma solidity 0.8.26;

import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "oz/utils/cryptography/MerkleProof.sol";
import {UUPSUpgradeable} from "oz-up/proxy/utils/UUPSUpgradeable.sol";

import {
    IMetrom,
    Campaign,
    Reward,
    ReadonlyCampaign,
    CreateBundle,
    RewardAmount,
    CreatedCampaignReward,
    DistributeRewardsBundle,
    SetMinimumRewardTokenRateBundle,
    ClaimRewardBundle,
    ClaimFeeBundle,
    UNIT,
    MAX_REWARDS_PER_CAMPAIGN
} from "./IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Metrom
/// @notice The contract handling all Metrom entities and interactions. It supports
/// creation and update of campaigns as well as claims and recoveries of unassigned
/// rewards for each one of them.
/// @author Federico Luzzi - <federico.luzzi@metrom.xyz>
contract Metrom is IMetrom, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    /// @inheritdoc IMetrom
    bool public override ossified;

    /// @inheritdoc IMetrom
    address public override owner;

    /// @inheritdoc IMetrom
    address public override pendingOwner;

    /// @inheritdoc IMetrom
    address public override updater;

    /// @inheritdoc IMetrom
    uint32 public override fee;

    /// @inheritdoc IMetrom
    uint32 public override minimumCampaignDuration;

    /// @inheritdoc IMetrom
    uint32 public override maximumCampaignDuration;
    mapping(bytes32 id => Campaign) internal campaigns;

    /// @inheritdoc IMetrom
    mapping(address account => uint32 rebate) public override feeRebate;

    /// @inheritdoc IMetrom
    mapping(address token => uint256 amount) public override claimableFees;

    /// @inheritdoc IMetrom
    mapping(address token => uint256 minimumRate) public override minimumRewardTokenRate;

    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc IMetrom
    function initialize(
        address _owner,
        address _updater,
        uint32 _fee,
        uint32 _minimumCampaignDuration,
        uint32 _maximumCampaignDuration
    ) external override initializer {
        if (_owner == address(0)) revert ZeroAddressOwner();
        if (_updater == address(0)) revert ZeroAddressUpdater();
        if (_fee >= UNIT) revert InvalidFee();
        if (_minimumCampaignDuration >= _maximumCampaignDuration) revert InvalidMinimumCampaignDuration();

        owner = _owner;
        updater = _updater;
        minimumCampaignDuration = _minimumCampaignDuration;
        maximumCampaignDuration = _maximumCampaignDuration;
        fee = _fee;

        emit Initialize(_owner, _updater, _fee, _minimumCampaignDuration, _maximumCampaignDuration);
    }

    /// @inheritdoc IMetrom
    function ossify() external {
        if (msg.sender != owner) revert Forbidden();
        ossified = true;
        emit Ossify();
    }

    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != owner) revert Forbidden();
        if (ossified) revert Ossified();
    }

    function _campaignId(CreateBundle memory _bundle) internal view returns (bytes32) {
        return keccak256(
            abi.encode(msg.sender, _bundle.pool, _bundle.from, _bundle.to, _bundle.specification, _bundle.rewards)
        );
    }

    function _getExistingCampaign(bytes32 _id) internal view returns (Campaign storage) {
        Campaign storage campaign = campaigns[_id];
        if (campaign.from == 0) revert NonExistentCampaign();
        return campaign;
    }

    function _getExistingCampaignReward(bytes32 _id, address _token) internal view returns (Reward storage) {
        return _getExistingCampaign(_id).reward[_token];
    }

    function _resolvedFee() internal view returns (uint32) {
        return uint32(uint64(fee) * (UNIT - feeRebate[msg.sender]) / UNIT);
    }

    /// @inheritdoc IMetrom
    function campaignById(bytes32 _id) external view override returns (ReadonlyCampaign memory) {
        Campaign storage campaign = _getExistingCampaign(_id);
        return ReadonlyCampaign({
            owner: campaign.owner,
            pendingOwner: campaign.pendingOwner,
            pool: campaign.pool,
            from: campaign.from,
            to: campaign.to,
            specification: campaign.specification,
            root: campaign.root,
            data: campaign.data
        });
    }

    /// @inheritdoc IMetrom
    function campaignReward(bytes32 _id, address _token) external view override returns (uint256) {
        return _getExistingCampaignReward(_id, _token).amount;
    }

    /// @inheritdoc IMetrom
    function claimedCampaignReward(bytes32 _id, address _token, address _account)
        external
        view
        override
        returns (uint256)
    {
        return _getExistingCampaignReward(_id, _token).claimed[_account];
    }

    /// @inheritdoc IMetrom
    function createCampaigns(CreateBundle[] calldata _bundles) external {
        uint32 _fee = _resolvedFee();
        uint32 _minimumCampaignDuration = minimumCampaignDuration;
        uint32 _maximumCampaignDuration = maximumCampaignDuration;

        for (uint256 _i = 0; _i < _bundles.length; _i++) {
            CreateBundle memory _bundle = _bundles[_i];

            if (_bundle.pool == address(0)) revert ZeroAddressPool();
            if (_bundle.from <= block.timestamp) revert StartTimeInThePast();
            if (_bundle.to < _bundle.from + _minimumCampaignDuration) revert DurationTooShort();
            uint32 _duration = _bundle.to - _bundle.from;
            if (_duration > _maximumCampaignDuration) revert DurationTooLong();
            if (_bundle.rewards.length == 0) revert NoRewards();
            if (_bundle.rewards.length > MAX_REWARDS_PER_CAMPAIGN) revert TooManyRewards();

            bytes32 _id = _campaignId(_bundle);
            Campaign storage campaign = campaigns[_id];
            if (campaign.from != 0) revert AlreadyExists();

            campaign.owner = msg.sender;
            campaign.pool = _bundle.pool;
            campaign.from = _bundle.from;
            campaign.to = _bundle.to;
            campaign.specification = _bundle.specification;

            CreatedCampaignReward[] memory _createdCampaignRewards = new CreatedCampaignReward[](_bundle.rewards.length);
            for (uint256 _j = 0; _j < _bundle.rewards.length; _j++) {
                RewardAmount memory _reward = _bundle.rewards[_j];

                address _token = _reward.token;
                if (_token == address(0)) revert ZeroAddressRewardToken();

                uint256 _amount = _reward.amount;
                if (_amount == 0) revert ZeroRewardAmount();

                {
                    // avoids stack too deep
                    uint256 _minimumRewardTokenRate = minimumRewardTokenRate[_token];
                    if (_minimumRewardTokenRate == 0) revert DisallowedRewardToken();
                    if (_amount * 1 hours / _duration < _minimumRewardTokenRate) revert RewardAmountTooLow();
                }

                uint256 _balanceBefore = IERC20(_token).balanceOf(address(this));
                IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
                _amount = IERC20(_token).balanceOf(address(this)) - _balanceBefore;
                if (_amount == 0) revert ZeroRewardAmount();

                uint256 _feeAmount = _amount * _fee / UNIT;
                uint256 _rewardAmountMinusFees = _amount - _feeAmount;
                claimableFees[_token] += _feeAmount;

                _createdCampaignRewards[_j] =
                    CreatedCampaignReward({token: _token, amount: _rewardAmountMinusFees, fee: _feeAmount});

                Reward storage reward = campaign.reward[_token];
                reward.amount += _rewardAmountMinusFees;
            }

            emit CreateCampaign(
                _id, msg.sender, _bundle.pool, _bundle.from, _bundle.to, _bundle.specification, _createdCampaignRewards
            );
        }
    }

    /// @inheritdoc IMetrom
    function distributeRewards(DistributeRewardsBundle[] calldata _bundles) external override {
        if (msg.sender != updater) revert Forbidden();

        for (uint256 _i; _i < _bundles.length; _i++) {
            DistributeRewardsBundle calldata _bundle = _bundles[_i];
            if (_bundle.root == bytes32(0)) revert ZeroRoot();
            if (_bundle.data == bytes32(0)) revert ZeroData();

            Campaign storage campaign = _getExistingCampaign(_bundle.campaignId);
            campaign.root = _bundle.root;
            campaign.data = _bundle.data;
            emit DistributeReward(_bundle.campaignId, _bundle.root, _bundle.data);
        }
    }

    /// @inheritdoc IMetrom
    function setMinimumRewardTokenRates(SetMinimumRewardTokenRateBundle[] calldata _bundles) external override {
        if (msg.sender != updater) revert Forbidden();

        for (uint256 _i; _i < _bundles.length; _i++) {
            SetMinimumRewardTokenRateBundle calldata _bundle = _bundles[_i];
            if (_bundle.token == address(0)) revert ZeroAddressRewardToken();

            minimumRewardTokenRate[_bundle.token] = _bundle.minimumRate;
            emit SetMinimumRewardTokenRate(_bundle.token, _bundle.minimumRate);
        }
    }

    function _processRewardClaim(Campaign storage campaign, ClaimRewardBundle calldata _bundle, address _claimOwner)
        internal
        returns (uint256)
    {
        if (_bundle.receiver == address(0)) revert ZeroAddressReceiver();
        if (_bundle.token == address(0)) revert ZeroAddressRewardToken();
        if (_bundle.amount == 0) revert ZeroAmount();

        bytes32 _leaf = keccak256(bytes.concat(keccak256(abi.encode(_claimOwner, _bundle.token, _bundle.amount))));
        if (!MerkleProof.verifyCalldata(_bundle.proof, campaign.root, _leaf)) revert InvalidProof();

        Reward storage reward = campaign.reward[_bundle.token];
        uint256 _claimAmount = _bundle.amount - reward.claimed[_claimOwner];
        if (_claimAmount == 0) revert ZeroAmount();
        if (_claimAmount > reward.amount) revert TooMuchClaimedAmount();

        reward.claimed[_claimOwner] += _claimAmount;
        reward.amount -= _claimAmount;

        IERC20(_bundle.token).safeTransfer(_bundle.receiver, _claimAmount);

        return _claimAmount;
    }

    /// @inheritdoc IMetrom
    function claimRewards(ClaimRewardBundle[] calldata _bundles) external override {
        for (uint256 _i; _i < _bundles.length; _i++) {
            ClaimRewardBundle calldata _bundle = _bundles[_i];
            uint256 _claimedAmount = _processRewardClaim(_getExistingCampaign(_bundle.campaignId), _bundle, msg.sender);
            emit ClaimReward(_bundle.campaignId, _bundle.token, _claimedAmount, _bundle.receiver);
        }
    }

    /// @inheritdoc IMetrom
    function recoverRewards(ClaimRewardBundle[] calldata _bundles) external override {
        for (uint256 _i; _i < _bundles.length; _i++) {
            ClaimRewardBundle calldata _bundle = _bundles[_i];

            Campaign storage campaign = _getExistingCampaign(_bundle.campaignId);
            if (msg.sender != campaign.owner) revert Forbidden();

            uint256 _claimedAmount = _processRewardClaim(campaign, _bundle, address(0));
            emit RecoverReward(_bundle.campaignId, _bundle.token, _claimedAmount, _bundle.receiver);
        }
    }

    /// @inheritdoc IMetrom
    function claimFees(ClaimFeeBundle[] calldata _bundles) external {
        if (msg.sender != owner) revert Forbidden();

        for (uint256 _i = 0; _i < _bundles.length; _i++) {
            ClaimFeeBundle calldata _bundle = _bundles[_i];

            if (_bundle.token == address(0)) revert ZeroAddressRewardToken();
            if (_bundle.receiver == address(0)) revert ZeroAddressReceiver();

            uint256 _claimAmount = claimableFees[_bundle.token];
            if (_claimAmount == 0) revert ZeroAmount();

            delete claimableFees[_bundle.token];
            IERC20(_bundle.token).safeTransfer(_bundle.receiver, _claimAmount);
            emit ClaimFee(_bundle.token, _claimAmount, _bundle.receiver);
        }
    }

    /// @inheritdoc IMetrom
    function campaignOwner(bytes32 _id) external view override returns (address) {
        return campaigns[_id].owner;
    }

    /// @inheritdoc IMetrom
    function campaignPendingOwner(bytes32 _id) external view override returns (address) {
        return campaigns[_id].pendingOwner;
    }

    /// @inheritdoc IMetrom
    function transferCampaignOwnership(bytes32 _id, address _owner) external override {
        if (_owner == address(0)) revert ZeroAddressOwner();
        Campaign storage campaign = _getExistingCampaign(_id);
        if (msg.sender != campaign.owner) revert Forbidden();
        campaign.pendingOwner = _owner;
        emit TransferCampaignOwnership(_id, _owner);
    }

    /// @inheritdoc IMetrom
    function acceptCampaignOwnership(bytes32 _id) external override {
        Campaign storage campaign = _getExistingCampaign(_id);
        if (msg.sender != campaign.pendingOwner) revert Forbidden();
        delete campaign.pendingOwner;
        campaign.owner = msg.sender;
        emit AcceptCampaignOwnership(_id, msg.sender);
    }

    /// @inheritdoc IMetrom
    function transferOwnership(address _owner) external override {
        if (_owner == address(0)) revert ZeroAddressOwner();
        if (msg.sender != owner) revert Forbidden();
        pendingOwner = _owner;
        emit TransferOwnership(_owner);
    }

    /// @inheritdoc IMetrom
    function acceptOwnership() external override {
        if (msg.sender != pendingOwner) revert Forbidden();
        delete pendingOwner;
        owner = msg.sender;
        emit AcceptOwnership(msg.sender);
    }

    /// @inheritdoc IMetrom
    function setUpdater(address _updater) external override {
        if (msg.sender != owner) revert Forbidden();
        if (_updater == address(0)) revert ZeroAddressUpdater();
        updater = _updater;
        emit SetUpdater(_updater);
    }

    /// @inheritdoc IMetrom
    function setFee(uint32 _fee) external override {
        if (_fee >= UNIT) revert InvalidFee();
        if (msg.sender != owner) revert Forbidden();
        fee = _fee;
        emit SetFee(_fee);
    }

    /// @inheritdoc IMetrom
    function setFeeRebate(address _account, uint32 _rebate) external override {
        if (_account == address(0)) revert ZeroAddressAccount();
        if (_rebate > UNIT) revert RebateTooHigh();
        if (msg.sender != owner) revert Forbidden();
        feeRebate[_account] = _rebate;
        emit SetFeeRebate(_account, _rebate);
    }

    /// @inheritdoc IMetrom
    function setMinimumCampaignDuration(uint32 _minimumCampaignDuration) external override {
        if (_minimumCampaignDuration >= maximumCampaignDuration) revert InvalidMinimumCampaignDuration();
        if (msg.sender != owner) revert Forbidden();
        minimumCampaignDuration = _minimumCampaignDuration;
        emit SetMinimumCampaignDuration(_minimumCampaignDuration);
    }

    /// @inheritdoc IMetrom
    function setMaximumCampaignDuration(uint32 _maximumCampaignDuration) external override {
        if (_maximumCampaignDuration <= minimumCampaignDuration) revert InvalidMaximumCampaignDuration();
        if (msg.sender != owner) revert Forbidden();
        maximumCampaignDuration = _maximumCampaignDuration;
        emit SetMaximumCampaignDuration(_maximumCampaignDuration);
    }
}
