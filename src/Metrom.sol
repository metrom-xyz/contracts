pragma solidity 0.8.28;

import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "oz/utils/cryptography/MerkleProof.sol";
import {UUPSUpgradeable} from "oz-up/proxy/utils/UUPSUpgradeable.sol";

import {BaseCampaignsUtils} from "./libraries/BaseCampaignsUtils.sol";
import {RewardsCampaignsV1, RewardsCampaignsV1Utils} from "./libraries/RewardsCampaignsV1Utils.sol";
import {
    RewardsCampaignsV2,
    RewardsCampaignsV2Utils,
    MAX_REWARDS_PER_CAMPAIGN
} from "./libraries/RewardsCampaignsV2Utils.sol";
import {PointsCampaignsV1, PointsCampaignsV1Utils} from "./libraries/PointsCampaignsV1Utils.sol";
import {PointsCampaignsV2, PointsCampaignsV2Utils} from "./libraries/PointsCampaignsV2Utils.sol";
import {
    IMetrom,
    RewardsCampaignV1,
    RewardsCampaignV2,
    Reward,
    PointsCampaignV1,
    PointsCampaignV2,
    ReadonlyRewardsCampaign,
    ReadonlyPointsCampaign,
    CreateRewardsCampaignBundle,
    CreatePointsCampaignBundle,
    RewardAmount,
    CreatedCampaignReward,
    DistributeRewardsBundle,
    SetMinimumTokenRateBundle,
    ClaimRewardBundle,
    ClaimFeeBundle,
    UNIT
} from "./IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Metrom
/// @notice The contract handling all Metrom entities and interactions. It supports
/// creation and update of campaigns as well as claims and recoveries of unassigned
/// rewards for each one of them.
/// @author Federico Luzzi - <federico.luzzi@metrom.xyz>
contract Metrom is IMetrom, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    using RewardsCampaignsV1Utils for RewardsCampaignsV1;
    using RewardsCampaignsV2Utils for RewardsCampaignsV2;

    using PointsCampaignsV1Utils for PointsCampaignsV1;
    using PointsCampaignsV2Utils for PointsCampaignsV2;

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

    RewardsCampaignsV1 internal rewardsCampaignsV1;

    /// @inheritdoc IMetrom
    mapping(address account => uint32 rebate) public override feeRebate;

    /// @inheritdoc IMetrom
    mapping(address token => uint256 amount) public override claimableFees;

    /// @inheritdoc IMetrom
    mapping(address token => uint256 minimumRate) public override minimumRewardTokenRate;

    /// @inheritdoc IMetrom
    mapping(address token => uint256 minimumRate) public override minimumFeeTokenRate;

    PointsCampaignsV1 internal pointsCampaignsV1;

    RewardsCampaignsV2 internal rewardsCampaignsV2;

    PointsCampaignsV2 internal pointsCampaignsV2;

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

    /// @inheritdoc IMetrom
    function rewardsCampaignById(bytes32 _id) external view override returns (ReadonlyRewardsCampaign memory) {
        RewardsCampaignV1 storage campaignV1 = rewardsCampaignsV1.get(_id);
        return campaignV1.from != 0
            ? ReadonlyRewardsCampaign({
                owner: campaignV1.owner,
                pendingOwner: campaignV1.pendingOwner,
                from: campaignV1.from,
                to: campaignV1.to,
                kind: 1,
                data: abi.encode(campaignV1.pool),
                specificationHash: campaignV1.specificationHash,
                dataHash: campaignV1.dataHash,
                root: campaignV1.root
            })
            : rewardsCampaignsV2.getExistingReadonly(_id);
    }

    /// @inheritdoc IMetrom
    function pointsCampaignById(bytes32 _id) external view override returns (ReadonlyPointsCampaign memory) {
        PointsCampaignV1 storage campaignV1 = pointsCampaignsV1.get(_id);
        return campaignV1.from != 0
            ? ReadonlyPointsCampaign({
                owner: campaignV1.owner,
                pendingOwner: campaignV1.pendingOwner,
                from: campaignV1.from,
                to: campaignV1.to,
                kind: 1,
                data: abi.encode(campaignV1.pool),
                specificationHash: campaignV1.specificationHash,
                points: campaignV1.points
            })
            : pointsCampaignsV2.getExistingReadonly(_id);
    }

    /// @inheritdoc IMetrom
    function campaignReward(bytes32 _id, address _token) external view override returns (uint256) {
        RewardsCampaignV1 storage campaignV1 = rewardsCampaignsV1.get(_id);
        return campaignV1.from != 0
            ? campaignV1.reward[_token].amount
            : rewardsCampaignsV2.getRewardOnExistingCampaign(_id, _token).amount;
    }

    /// @inheritdoc IMetrom
    function claimedCampaignReward(bytes32 _id, address _token, address _account)
        external
        view
        override
        returns (uint256)
    {
        RewardsCampaignV1 storage campaignV1 = rewardsCampaignsV1.get(_id);
        return campaignV1.from != 0
            ? campaignV1.reward[_token].claimed[_account]
            : rewardsCampaignsV2.getRewardOnExistingCampaign(_id, _token).claimed[_account];
    }

    /// @inheritdoc IMetrom
    function createCampaigns(
        CreateRewardsCampaignBundle[] calldata _rewardsCampaignBundles,
        CreatePointsCampaignBundle[] calldata _pointsCampaignBundles
    ) external {
        uint32 _fee = fee;
        uint32 _feeRebate = feeRebate[msg.sender];
        uint32 _resolvedRewardsCampaignFee = uint32(uint64(_fee) * (UNIT - _feeRebate) / UNIT);
        uint32 _minimumCampaignDuration = minimumCampaignDuration;
        uint32 _maximumCampaignDuration = maximumCampaignDuration;

        for (uint256 _i = 0; _i < _rewardsCampaignBundles.length; _i++) {
            CreateRewardsCampaignBundle calldata _rewardsCampaignBundle = _rewardsCampaignBundles[_i];
            (bytes32 _id, CreatedCampaignReward[] memory _createdCampaignRewards) = createRewardsCampaign(
                _rewardsCampaignBundle, _minimumCampaignDuration, _maximumCampaignDuration, _resolvedRewardsCampaignFee
            );
            emit CreateRewardsCampaign(
                _id,
                msg.sender,
                _rewardsCampaignBundle.from,
                _rewardsCampaignBundle.to,
                _rewardsCampaignBundle.kind,
                _rewardsCampaignBundle.data,
                _rewardsCampaignBundle.specificationHash,
                _createdCampaignRewards
            );
        }

        for (uint256 _i = 0; _i < _pointsCampaignBundles.length; _i++) {
            CreatePointsCampaignBundle calldata _pointsCampaignBundle = _pointsCampaignBundles[_i];
            (bytes32 _id, uint256 _feeAmount) = createPointsCampaign(
                _pointsCampaignBundle, _minimumCampaignDuration, _maximumCampaignDuration, _feeRebate
            );
            emit CreatePointsCampaign(
                _id,
                msg.sender,
                _pointsCampaignBundle.from,
                _pointsCampaignBundle.to,
                _pointsCampaignBundle.kind,
                _pointsCampaignBundle.data,
                _pointsCampaignBundle.specificationHash,
                _pointsCampaignBundle.points,
                _pointsCampaignBundle.feeToken,
                _feeAmount
            );
        }
    }

    function createRewardsCampaign(
        CreateRewardsCampaignBundle memory _bundle,
        uint32 _minimumCampaignDuration,
        uint32 _maximumCampaignDuration,
        uint32 _resolvedFee
    ) internal returns (bytes32, CreatedCampaignReward[] memory) {
        uint32 _duration =
            BaseCampaignsUtils.validate(_bundle.from, _bundle.to, _minimumCampaignDuration, _maximumCampaignDuration);
        if (_bundle.rewards.length == 0) revert NoRewards();
        if (_bundle.rewards.length > MAX_REWARDS_PER_CAMPAIGN) revert TooManyRewards();

        (bytes32 _id, RewardsCampaignV2 storage campaign) = rewardsCampaignsV2.getNew(_bundle);
        campaign.owner = msg.sender;
        campaign.from = _bundle.from;
        campaign.to = _bundle.to;
        campaign.kind = _bundle.kind;
        campaign.data = _bundle.data;
        campaign.specificationHash = _bundle.specificationHash;

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

            uint256 _feeAmount = _amount * _resolvedFee / UNIT;
            uint256 _rewardAmountMinusFees = _amount - _feeAmount;
            claimableFees[_token] += _feeAmount;

            _createdCampaignRewards[_j] =
                CreatedCampaignReward({token: _token, amount: _rewardAmountMinusFees, fee: _feeAmount});

            campaign.reward[_token].amount += _rewardAmountMinusFees;
        }

        return (_id, _createdCampaignRewards);
    }

    function createPointsCampaign(
        CreatePointsCampaignBundle memory _bundle,
        uint32 _minimumCampaignDuration,
        uint32 _maximumCampaignDuration,
        uint32 _feeRebate
    ) internal returns (bytes32, uint256) {
        uint32 _duration =
            BaseCampaignsUtils.validate(_bundle.from, _bundle.to, _minimumCampaignDuration, _maximumCampaignDuration);
        if (_bundle.points == 0) revert NoPoints();

        uint256 _minimumFeeTokenRate = minimumFeeTokenRate[_bundle.feeToken];
        if (_minimumFeeTokenRate == 0) revert DisallowedFeeToken();
        uint256 _fullRequiredFeeAmount = _minimumFeeTokenRate * _duration / 1 hours;
        uint256 _requiredFeeAmount = _fullRequiredFeeAmount * (UNIT - _feeRebate) / UNIT;

        (bytes32 _id, PointsCampaignV2 storage campaign) = pointsCampaignsV2.getNew(_bundle);
        campaign.owner = msg.sender;
        campaign.from = _bundle.from;
        campaign.to = _bundle.to;
        campaign.kind = _bundle.kind;
        campaign.data = _bundle.data;
        campaign.specificationHash = _bundle.specificationHash;
        campaign.points = _bundle.points;

        uint256 _feeAmount = collectPointsCampaignFee(_bundle.feeToken, _requiredFeeAmount);

        return (_id, _feeAmount);
    }

    function collectPointsCampaignFee(address _feeToken, uint256 _requiredFeeAmount) internal returns (uint256) {
        uint256 _balanceBefore = IERC20(_feeToken).balanceOf(address(this));
        IERC20(_feeToken).safeTransferFrom(msg.sender, address(this), _requiredFeeAmount);
        uint256 _collectedFeeAmount = IERC20(_feeToken).balanceOf(address(this)) - _balanceBefore;
        if (_collectedFeeAmount < _requiredFeeAmount) revert FeeAmountTooLow();
        claimableFees[_feeToken] += _collectedFeeAmount;
        return _collectedFeeAmount;
    }

    /// @inheritdoc IMetrom
    function distributeRewards(DistributeRewardsBundle[] calldata _bundles) external override {
        if (msg.sender != updater) revert Forbidden();

        for (uint256 _i; _i < _bundles.length; _i++) {
            DistributeRewardsBundle calldata _bundle = _bundles[_i];
            if (_bundle.root == bytes32(0)) revert ZeroRoot();
            if (_bundle.dataHash == bytes32(0)) revert ZeroData();

            RewardsCampaignV1 storage campaignV1 = rewardsCampaignsV1.get(_bundle.campaignId);
            if (campaignV1.from != 0) {
                campaignV1.root = _bundle.root;
                campaignV1.dataHash = _bundle.dataHash;
            } else {
                RewardsCampaignV2 storage campaignV2 = rewardsCampaignsV2.getExisting(_bundle.campaignId);
                campaignV2.root = _bundle.root;
                campaignV2.dataHash = _bundle.dataHash;
            }

            emit DistributeReward(_bundle.campaignId, _bundle.root, _bundle.dataHash);
        }
    }

    /// @inheritdoc IMetrom
    function setMinimumTokenRates(
        SetMinimumTokenRateBundle[] calldata _rewardTokenBundles,
        SetMinimumTokenRateBundle[] calldata _feeTokenBundles
    ) external override {
        if (msg.sender != updater) revert Forbidden();

        for (uint256 _i; _i < _rewardTokenBundles.length; _i++) {
            SetMinimumTokenRateBundle calldata _bundle = _rewardTokenBundles[_i];
            if (_bundle.token == address(0)) revert ZeroAddressRewardToken();

            minimumRewardTokenRate[_bundle.token] = _bundle.minimumRate;
            emit SetMinimumRewardTokenRate(_bundle.token, _bundle.minimumRate);
        }

        for (uint256 _i; _i < _feeTokenBundles.length; _i++) {
            SetMinimumTokenRateBundle calldata _bundle = _feeTokenBundles[_i];
            if (_bundle.token == address(0)) revert ZeroAddressFeeToken();

            minimumFeeTokenRate[_bundle.token] = _bundle.minimumRate;
            emit SetMinimumFeeTokenRate(_bundle.token, _bundle.minimumRate);
        }
    }

    function _processRewardClaim(
        bytes32 _campaignRoot,
        Reward storage reward,
        ClaimRewardBundle calldata _bundle,
        address _claimOwner
    ) internal returns (uint256) {
        if (_bundle.receiver == address(0)) revert ZeroAddressReceiver();
        if (_bundle.token == address(0)) revert ZeroAddressRewardToken();
        if (_bundle.amount == 0) revert ZeroAmount();

        bytes32 _leaf = keccak256(bytes.concat(keccak256(abi.encode(_claimOwner, _bundle.token, _bundle.amount))));
        if (!MerkleProof.verifyCalldata(_bundle.proof, _campaignRoot, _leaf)) revert InvalidProof();

        uint256 _claimAmount = _bundle.amount - reward.claimed[_claimOwner];
        if (_claimAmount == 0) revert ZeroAmount();
        if (_claimAmount > reward.amount) revert TooMuchClaimedAmount();

        reward.claimed[_claimOwner] += _claimAmount;
        reward.amount -= _claimAmount;

        IERC20(_bundle.token).safeTransfer(_bundle.receiver, _claimAmount);

        return _claimAmount;
    }

    function _claimableRewardAndRoot(ClaimRewardBundle calldata _bundle, bool _checkOwner)
        internal
        view
        returns (bytes32, Reward storage)
    {
        RewardsCampaignV1 storage rewardsCampaignV1 = rewardsCampaignsV1.get(_bundle.campaignId);
        if (rewardsCampaignV1.from != 0) {
            if (_checkOwner && rewardsCampaignV1.owner != msg.sender) revert Forbidden();
            return (rewardsCampaignV1.root, rewardsCampaignV1.reward[_bundle.token]);
        }

        RewardsCampaignV2 storage rewardsCampaignV2 = rewardsCampaignsV2.getExisting(_bundle.campaignId);
        if (_checkOwner && rewardsCampaignV2.owner != msg.sender) revert Forbidden();
        return (rewardsCampaignV2.root, rewardsCampaignV2.reward[_bundle.token]);
    }

    /// @inheritdoc IMetrom
    function claimRewards(ClaimRewardBundle[] calldata _bundles) external override {
        for (uint256 _i; _i < _bundles.length; _i++) {
            ClaimRewardBundle calldata _bundle = _bundles[_i];
            (bytes32 _root, Reward storage claimableReward) = _claimableRewardAndRoot(_bundle, false);
            uint256 _claimedAmount = _processRewardClaim(_root, claimableReward, _bundle, msg.sender);
            emit ClaimReward(_bundle.campaignId, _bundle.token, _claimedAmount, _bundle.receiver);
        }
    }

    /// @inheritdoc IMetrom
    function recoverRewards(ClaimRewardBundle[] calldata _bundles) external override {
        for (uint256 _i; _i < _bundles.length; _i++) {
            ClaimRewardBundle calldata _bundle = _bundles[_i];
            (bytes32 _root, Reward storage claimableReward) = _claimableRewardAndRoot(_bundle, true);
            uint256 _claimedAmount = _processRewardClaim(_root, claimableReward, _bundle, address(0));
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
        address _owner = rewardsCampaignsV1.get(_id).owner;
        if (_owner == address(0)) _owner = rewardsCampaignsV2.get(_id).owner;
        if (_owner == address(0)) _owner = pointsCampaignsV1.get(_id).owner;
        if (_owner == address(0)) _owner = pointsCampaignsV2.get(_id).owner;
        return _owner;
    }

    /// @inheritdoc IMetrom
    function campaignPendingOwner(bytes32 _id) external view override returns (address) {
        address _pendingOwner = rewardsCampaignsV1.get(_id).pendingOwner;
        if (_pendingOwner == address(0)) _pendingOwner = rewardsCampaignsV2.get(_id).pendingOwner;
        if (_pendingOwner == address(0)) _pendingOwner = pointsCampaignsV1.get(_id).pendingOwner;
        if (_pendingOwner == address(0)) _pendingOwner = pointsCampaignsV2.get(_id).pendingOwner;
        return _pendingOwner;
    }

    /// @inheritdoc IMetrom
    function transferCampaignOwnership(bytes32 _id, address _owner) external override {
        if (_owner == address(0)) revert ZeroAddressOwner();

        RewardsCampaignV1 storage rewardsCampaignV1 = rewardsCampaignsV1.get(_id);
        if (rewardsCampaignV1.from != 0) {
            if (msg.sender != rewardsCampaignV1.owner) revert Forbidden();
            rewardsCampaignV1.pendingOwner = _owner;
            emit TransferCampaignOwnership(_id, _owner);
            return;
        }

        RewardsCampaignV2 storage rewardsCampaignV2 = rewardsCampaignsV2.get(_id);
        if (rewardsCampaignV2.from != 0) {
            if (msg.sender != rewardsCampaignV2.owner) revert Forbidden();
            rewardsCampaignV2.pendingOwner = _owner;
            emit TransferCampaignOwnership(_id, _owner);
            return;
        }

        PointsCampaignV1 storage pointsCampaignV1 = pointsCampaignsV1.get(_id);
        if (pointsCampaignV1.owner != address(0)) {
            if (msg.sender != pointsCampaignV1.owner) revert Forbidden();
            pointsCampaignV1.pendingOwner = _owner;
            emit TransferCampaignOwnership(_id, _owner);
            return;
        }

        PointsCampaignV2 storage pointsCampaignV2 = pointsCampaignsV2.get(_id);
        if (pointsCampaignV2.owner != address(0)) {
            if (msg.sender != pointsCampaignV2.owner) revert Forbidden();
            pointsCampaignV2.pendingOwner = _owner;
            emit TransferCampaignOwnership(_id, _owner);
            return;
        }

        revert NonExistentCampaign();
    }

    /// @inheritdoc IMetrom
    function acceptCampaignOwnership(bytes32 _id) external override {
        RewardsCampaignV1 storage rewardsCampaignV1 = rewardsCampaignsV1.get(_id);
        if (rewardsCampaignV1.owner != address(0)) {
            if (msg.sender != rewardsCampaignV1.pendingOwner) revert Forbidden();
            delete rewardsCampaignV1.pendingOwner;
            rewardsCampaignV1.owner = msg.sender;
            emit AcceptCampaignOwnership(_id, msg.sender);
            return;
        }

        RewardsCampaignV2 storage rewardsCampaignV2 = rewardsCampaignsV2.get(_id);
        if (rewardsCampaignV2.owner != address(0)) {
            if (msg.sender != rewardsCampaignV2.pendingOwner) revert Forbidden();
            delete rewardsCampaignV2.pendingOwner;
            rewardsCampaignV2.owner = msg.sender;
            emit AcceptCampaignOwnership(_id, msg.sender);
            return;
        }

        PointsCampaignV1 storage pointsCampaignV1 = pointsCampaignsV1.get(_id);
        if (pointsCampaignV1.owner != address(0)) {
            if (msg.sender != pointsCampaignV1.pendingOwner) revert Forbidden();
            delete pointsCampaignV1.pendingOwner;
            pointsCampaignV1.owner = msg.sender;
            emit AcceptCampaignOwnership(_id, msg.sender);
            return;
        }

        PointsCampaignV2 storage pointsCampaignV2 = pointsCampaignsV2.get(_id);
        if (pointsCampaignV2.owner != address(0)) {
            if (msg.sender != pointsCampaignV2.pendingOwner) revert Forbidden();
            delete pointsCampaignV2.pendingOwner;
            pointsCampaignV2.owner = msg.sender;
            emit AcceptCampaignOwnership(_id, msg.sender);
            return;
        }

        revert NonExistentCampaign();
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
