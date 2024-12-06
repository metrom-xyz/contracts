pragma solidity 0.8.28;

import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "oz/utils/cryptography/MerkleProof.sol";
import {UUPSUpgradeable} from "oz-up/proxy/utils/UUPSUpgradeable.sol";

import {BaseCampaignsUtils} from "./libraries/BaseCampaignsUtils.sol";
import {
    RewardsCampaigns, RewardsCampaignsUtils, MAX_REWARDS_PER_CAMPAIGN
} from "./libraries/RewardsCampaignsUtils.sol";
import {PointsCampaigns, PointsCampaignsUtils} from "./libraries/PointsCampaignsUtils.sol";
import {
    IMetrom,
    RewardsCampaign,
    Reward,
    PointsCampaign,
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
    using RewardsCampaignsUtils for RewardsCampaigns;
    using PointsCampaignsUtils for PointsCampaigns;

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

    RewardsCampaigns internal rewardsCampaigns;

    /// @inheritdoc IMetrom
    mapping(address account => uint32 rebate) public override feeRebate;

    /// @inheritdoc IMetrom
    mapping(address token => uint256 amount) public override claimableFees;

    /// @inheritdoc IMetrom
    mapping(address token => uint256 minimumRate) public override minimumRewardTokenRate;

    /// @inheritdoc IMetrom
    mapping(address token => uint256 minimumRate) public override minimumFeeTokenRate;

    PointsCampaigns internal pointsCampaigns;

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

    function _resolvedRewardsCampaignFee() internal view returns (uint32) {
        return uint32(uint64(fee) * (UNIT - feeRebate[msg.sender]) / UNIT);
    }

    /// @inheritdoc IMetrom
    function rewardsCampaignById(bytes32 _id) external view override returns (ReadonlyRewardsCampaign memory) {
        return rewardsCampaigns.getExistingReadonly(_id);
    }

    /// @inheritdoc IMetrom
    function pointsCampaignById(bytes32 _id) external view override returns (ReadonlyPointsCampaign memory) {
        return pointsCampaigns.getExistingReadonly(_id);
    }

    /// @inheritdoc IMetrom
    function campaignReward(bytes32 _id, address _token) external view override returns (uint256) {
        return rewardsCampaigns.getRewardOnExistingCampaign(_id, _token).amount;
    }

    /// @inheritdoc IMetrom
    function claimedCampaignReward(bytes32 _id, address _token, address _account)
        external
        view
        override
        returns (uint256)
    {
        return rewardsCampaigns.getRewardOnExistingCampaign(_id, _token).claimed[_account];
    }

    /// @inheritdoc IMetrom
    function createCampaigns(
        CreateRewardsCampaignBundle[] calldata _rewardsCampaignBundles,
        CreatePointsCampaignBundle[] calldata _pointsCampaignBundles
    ) external {
        uint32 _resolvedFee = _resolvedRewardsCampaignFee();
        uint32 _minimumCampaignDuration = minimumCampaignDuration;
        uint32 _maximumCampaignDuration = maximumCampaignDuration;

        for (uint256 _i = 0; _i < _rewardsCampaignBundles.length; _i++) {
            CreateRewardsCampaignBundle calldata _rewardsCampaignBundle = _rewardsCampaignBundles[_i];
            (bytes32 _id, CreatedCampaignReward[] memory _createdCampaignRewards) = createRewardsCampaign(
                _rewardsCampaignBundle, _minimumCampaignDuration, _maximumCampaignDuration, _resolvedFee
            );
            emit CreateRewardsCampaign(
                _id,
                msg.sender,
                _rewardsCampaignBundle.pool,
                _rewardsCampaignBundle.from,
                _rewardsCampaignBundle.to,
                _rewardsCampaignBundle.specification,
                _createdCampaignRewards
            );
        }

        for (uint256 _i = 0; _i < _pointsCampaignBundles.length; _i++) {
            CreatePointsCampaignBundle calldata _pointsCampaignBundle = _pointsCampaignBundles[_i];
            (bytes32 _id, uint256 _feeAmount) =
                createPointsCampaign(_pointsCampaignBundle, _minimumCampaignDuration, _maximumCampaignDuration);
            emit CreatePointsCampaign(
                _id,
                msg.sender,
                _pointsCampaignBundle.pool,
                _pointsCampaignBundle.from,
                _pointsCampaignBundle.to,
                _pointsCampaignBundle.specification,
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
        uint32 _duration = BaseCampaignsUtils.validate(
            _bundle.pool, _bundle.from, _bundle.to, _minimumCampaignDuration, _maximumCampaignDuration
        );
        if (_bundle.rewards.length == 0) revert NoRewards();
        if (_bundle.rewards.length > MAX_REWARDS_PER_CAMPAIGN) revert TooManyRewards();

        (bytes32 _id, RewardsCampaign storage campaign) = rewardsCampaigns.getNew(_bundle);
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

            uint256 _feeAmount = _amount * _resolvedFee / UNIT;
            uint256 _rewardAmountMinusFees = _amount - _feeAmount;
            claimableFees[_token] += _feeAmount;

            _createdCampaignRewards[_j] =
                CreatedCampaignReward({token: _token, amount: _rewardAmountMinusFees, fee: _feeAmount});

            Reward storage reward = campaign.reward[_token];
            reward.amount += _rewardAmountMinusFees;
        }

        return (_id, _createdCampaignRewards);
    }

    function createPointsCampaign(
        CreatePointsCampaignBundle memory _bundle,
        uint32 _minimumCampaignDuration,
        uint32 _maximumCampaignDuration
    ) internal returns (bytes32, uint256) {
        uint32 _duration = BaseCampaignsUtils.validate(
            _bundle.pool, _bundle.from, _bundle.to, _minimumCampaignDuration, _maximumCampaignDuration
        );
        if (_bundle.points == 0) revert NoPoints();

        uint256 _minimumFeeTokenRate = minimumFeeTokenRate[_bundle.feeToken];
        if (_minimumFeeTokenRate == 0) revert DisallowedFeeToken();
        uint256 _requiredFeeAmount = _minimumFeeTokenRate * _duration / 1 hours;

        (bytes32 _id, PointsCampaign storage campaign) = pointsCampaigns.getNew(_bundle);
        campaign.owner = msg.sender;
        campaign.pool = _bundle.pool;
        campaign.from = _bundle.from;
        campaign.to = _bundle.to;
        campaign.specification = _bundle.specification;
        campaign.points = _bundle.points;

        uint256 _balanceBefore = IERC20(_bundle.feeToken).balanceOf(address(this));
        IERC20(_bundle.feeToken).safeTransferFrom(msg.sender, address(this), _requiredFeeAmount);
        uint256 _feeAmount = IERC20(_bundle.feeToken).balanceOf(address(this)) - _balanceBefore;
        if (_feeAmount < _requiredFeeAmount) revert FeeAmountTooLow();
        claimableFees[_bundle.feeToken] += _feeAmount;

        return (_id, _feeAmount);
    }

    /// @inheritdoc IMetrom
    function distributeRewards(DistributeRewardsBundle[] calldata _bundles) external override {
        if (msg.sender != updater) revert Forbidden();

        for (uint256 _i; _i < _bundles.length; _i++) {
            DistributeRewardsBundle calldata _bundle = _bundles[_i];
            if (_bundle.root == bytes32(0)) revert ZeroRoot();
            if (_bundle.data == bytes32(0)) revert ZeroData();

            RewardsCampaign storage campaign = rewardsCampaigns.getExisting(_bundle.campaignId);
            campaign.root = _bundle.root;
            campaign.data = _bundle.data;
            emit DistributeReward(_bundle.campaignId, _bundle.root, _bundle.data);
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
        RewardsCampaign storage campaign,
        ClaimRewardBundle calldata _bundle,
        address _claimOwner
    ) internal returns (uint256) {
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
            uint256 _claimedAmount =
                _processRewardClaim(rewardsCampaigns.getExisting(_bundle.campaignId), _bundle, msg.sender);
            emit ClaimReward(_bundle.campaignId, _bundle.token, _claimedAmount, _bundle.receiver);
        }
    }

    /// @inheritdoc IMetrom
    function recoverRewards(ClaimRewardBundle[] calldata _bundles) external override {
        for (uint256 _i; _i < _bundles.length; _i++) {
            ClaimRewardBundle calldata _bundle = _bundles[_i];

            RewardsCampaign storage campaign = rewardsCampaigns.getExisting(_bundle.campaignId);
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
        address _owner = rewardsCampaigns.get(_id).owner;
        return _owner == address(0) ? pointsCampaigns.get(_id).owner : _owner;
    }

    /// @inheritdoc IMetrom
    function campaignPendingOwner(bytes32 _id) external view override returns (address) {
        address _pendingOwner = rewardsCampaigns.get(_id).pendingOwner;
        return _pendingOwner == address(0) ? pointsCampaigns.get(_id).pendingOwner : _pendingOwner;
    }

    /// @inheritdoc IMetrom
    function transferCampaignOwnership(bytes32 _id, address _owner) external override {
        if (_owner == address(0)) revert ZeroAddressOwner();

        RewardsCampaign storage rewardsCampaign = rewardsCampaigns.get(_id);
        if (rewardsCampaign.owner != address(0)) {
            if (msg.sender != rewardsCampaign.owner) revert Forbidden();
            rewardsCampaign.pendingOwner = _owner;
            emit TransferCampaignOwnership(_id, _owner);
            return;
        }

        PointsCampaign storage pointsCampaign = pointsCampaigns.get(_id);
        if (pointsCampaign.owner != address(0)) {
            if (msg.sender != pointsCampaign.owner) revert Forbidden();
            pointsCampaign.pendingOwner = _owner;
            emit TransferCampaignOwnership(_id, _owner);
            return;
        }

        revert NonExistentCampaign();
    }

    /// @inheritdoc IMetrom
    function acceptCampaignOwnership(bytes32 _id) external override {
        RewardsCampaign storage rewardsCampaign = rewardsCampaigns.get(_id);
        if (rewardsCampaign.owner != address(0)) {
            if (msg.sender != rewardsCampaign.pendingOwner) revert Forbidden();
            delete rewardsCampaign.pendingOwner;
            rewardsCampaign.owner = msg.sender;
            emit AcceptCampaignOwnership(_id, msg.sender);
            return;
        }

        PointsCampaign storage pointsCampaign = pointsCampaigns.get(_id);
        if (pointsCampaign.owner != address(0)) {
            if (msg.sender != pointsCampaign.pendingOwner) revert Forbidden();
            delete pointsCampaign.pendingOwner;
            pointsCampaign.owner = msg.sender;
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
