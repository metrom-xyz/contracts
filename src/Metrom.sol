pragma solidity 0.8.25;

import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "oz/utils/cryptography/MerkleProof.sol";
import {UUPSUpgradeable} from "oz-up/proxy/utils/UUPSUpgradeable.sol";

import {
    IMetrom,
    SpecificFee,
    Campaign,
    Reward,
    ReadonlyCampaign,
    ReadonlyReward,
    CreateBundle,
    DistributeRewardsBundle,
    ClaimRewardBundle,
    ClaimFeeBundle,
    UNIT,
    MAX_FEE,
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
    uint32 public override globalFee;

    /// @inheritdoc IMetrom
    uint32 public override minimumCampaignDuration;

    /// @inheritdoc IMetrom
    uint32 public override maximumCampaignDuration;
    mapping(bytes32 id => Campaign) internal campaigns;
    mapping(address account => SpecificFee) internal specificFee;

    /// @inheritdoc IMetrom
    mapping(address token => uint256 amount) public override claimableFees;

    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc IMetrom
    function initialize(
        address _owner,
        address _updater,
        uint32 _globalFee,
        uint32 _minimumCampaignDuration,
        uint32 _maximumCampaignDuration
    ) external override initializer {
        if (_owner == address(0)) revert InvalidOwner();
        if (_updater == address(0)) revert InvalidUpdater();
        if (_globalFee > MAX_FEE) revert InvalidGlobalFee();
        if (_minimumCampaignDuration >= _maximumCampaignDuration) revert InvalidMinimumCampaignDuration();

        owner = _owner;
        updater = _updater;
        minimumCampaignDuration = _minimumCampaignDuration;
        maximumCampaignDuration = _maximumCampaignDuration;
        globalFee = _globalFee;

        emit Initialize(_owner, _updater, _globalFee, _minimumCampaignDuration, _maximumCampaignDuration);
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
            abi.encode(
                msg.sender,
                _bundle.chainId,
                _bundle.pool,
                _bundle.from,
                _bundle.to,
                _bundle.specification,
                _bundle.rewardTokens,
                _bundle.rewardAmounts
            )
        );
    }

    function _getExistingCampaign(bytes32 _id) internal view returns (Campaign storage) {
        Campaign storage campaign = campaigns[_id];
        if (campaign.from == 0) revert NonExistentCampaign();
        return campaign;
    }

    function _resolvedFee() internal view returns (uint32) {
        SpecificFee memory _specificFee = specificFee[msg.sender];
        if (_specificFee.none) {
            return 0;
        } else if (_specificFee.fee > 0) {
            return _specificFee.fee;
        } else {
            return globalFee;
        }
    }

    /// @inheritdoc IMetrom
    function campaignById(bytes32 _id) external view override returns (ReadonlyCampaign memory) {
        Campaign storage campaign = _getExistingCampaign(_id);

        uint256 _rewardsLength = campaign.rewards.length;
        ReadonlyReward[] memory _rewards = new ReadonlyReward[](_rewardsLength);
        for (uint256 _i = 0; _i < _rewardsLength; _i++) {
            address _token = campaign.rewards[_i];
            Reward storage reward = campaign.reward[_token];
            _rewards[_i] = ReadonlyReward({token: _token, amount: reward.amount, unclaimed: reward.unclaimed});
        }

        return ReadonlyCampaign({
            owner: campaign.owner,
            pendingOwner: campaign.pendingOwner,
            chainId: campaign.chainId,
            pool: campaign.pool,
            from: campaign.from,
            to: campaign.to,
            specification: campaign.specification,
            root: campaign.root,
            rewards: _rewards
        });
    }

    /// @inheritdoc IMetrom
    function specificFeeFor(address _account) external view returns (SpecificFee memory) {
        SpecificFee memory _specificFee = specificFee[_account];
        return _specificFee;
    }

    /// @inheritdoc IMetrom
    function createCampaigns(CreateBundle[] calldata _bundles) external {
        uint32 _fee = _resolvedFee();
        uint32 _minimumCampaignDuration = minimumCampaignDuration;
        uint32 _maximumCampaignDuration = maximumCampaignDuration;

        for (uint256 _i = 0; _i < _bundles.length; _i++) {
            CreateBundle memory _bundle = _bundles[_i];

            if (_bundle.pool == address(0)) revert InvalidPool();
            if (_bundle.from <= block.timestamp) revert InvalidFrom();
            if (
                _bundle.to < _bundle.from + _minimumCampaignDuration
                    || _bundle.to - _bundle.from > _maximumCampaignDuration
            ) revert InvalidTo();
            if (
                _bundle.rewardTokens.length == 0 || _bundle.rewardTokens.length > MAX_REWARDS_PER_CAMPAIGN
                    || _bundle.rewardTokens.length != _bundle.rewardAmounts.length
            ) revert InvalidRewards();

            bytes32 _id = _campaignId(_bundle);
            Campaign storage campaign = campaigns[_id];
            if (campaign.from != 0) revert CampaignAlreadyExists();

            campaign.owner = msg.sender;
            campaign.chainId = _bundle.chainId;
            campaign.pool = _bundle.pool;
            campaign.from = _bundle.from;
            campaign.to = _bundle.to;
            campaign.specification = _bundle.specification;
            campaign.rewards = _bundle.rewardTokens;

            uint256[] memory _feeAmounts = new uint256[](_bundle.rewardTokens.length);
            uint256[] memory _rewardAmountsMinusFees = new uint256[](_bundle.rewardTokens.length);
            for (uint256 _j = 0; _j < _bundle.rewardTokens.length; _j++) {
                address _token = _bundle.rewardTokens[_j];
                if (_token == address(0)) revert InvalidRewards();

                uint256 _amount = _bundle.rewardAmounts[_j];
                if (_amount == 0) revert InvalidRewards();

                for (uint256 _k = _j + 1; _k < _bundle.rewardTokens.length; _k++) {
                    if (_token == _bundle.rewardTokens[_k]) revert InvalidRewards();
                }

                uint256 _feeAmount = _amount * _fee / UNIT;
                uint256 _rewardAmountMinusFees = _amount - _feeAmount;
                claimableFees[_token] += _feeAmount;

                _feeAmounts[_j] = _feeAmount;
                _rewardAmountsMinusFees[_j] = _rewardAmountMinusFees;

                Reward storage reward = campaign.reward[_token];
                reward.amount = _rewardAmountMinusFees;
                reward.unclaimed = _rewardAmountMinusFees;

                IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            }

            emit CreateCampaign(
                _id,
                msg.sender,
                _bundle.chainId,
                _bundle.pool,
                _bundle.from,
                _bundle.to,
                _bundle.specification,
                _bundle.rewardTokens,
                _rewardAmountsMinusFees,
                _feeAmounts
            );
        }
    }

    /// @inheritdoc IMetrom
    function distributeRewards(DistributeRewardsBundle[] calldata _bundles) external override {
        if (msg.sender != updater) revert Forbidden();

        for (uint256 _i; _i < _bundles.length; _i++) {
            DistributeRewardsBundle calldata _bundle = _bundles[_i];
            if (_bundle.root == bytes32(0)) revert InvalidRoot();
            if (_bundle.data == bytes32(0)) revert InvalidData();
            Campaign storage campaign = _getExistingCampaign(_bundle.campaignId);
            campaign.root = _bundle.root;
            campaign.data = _bundle.data;
            emit DistributeReward(_bundle.campaignId, _bundle.root, _bundle.data);
        }
    }

    function _processRewardClaim(Campaign storage campaign, ClaimRewardBundle calldata _bundle, address _claimOwner)
        internal
        returns (uint256)
    {
        if (_bundle.receiver == address(0)) revert InvalidReceiver();
        if (_bundle.token == address(0)) revert InvalidToken();
        if (_bundle.amount == 0) revert InvalidAmount();

        bytes32 _leaf = keccak256(bytes.concat(keccak256(abi.encode(_claimOwner, _bundle.token, _bundle.amount))));
        if (!MerkleProof.verifyCalldata(_bundle.proof, campaign.root, _leaf)) revert InvalidProof();

        Reward storage reward = campaign.reward[_bundle.token];
        uint256 _claimAmount = _bundle.amount - reward.claimed[_claimOwner];
        if (_claimAmount == 0) revert ZeroAmount();
        if (_claimAmount > reward.unclaimed) revert InvalidAmount();

        reward.claimed[_claimOwner] += _claimAmount;
        reward.unclaimed -= _claimAmount;

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

            if (_bundle.token == address(0)) revert InvalidToken();
            if (_bundle.receiver == address(0)) revert InvalidReceiver();

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
        if (_owner == address(0)) revert InvalidOwner();
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
        emit AcceptCampaignOwnership(_id);
    }

    /// @inheritdoc IMetrom
    function transferOwnership(address _owner) external override {
        if (_owner == address(0)) revert InvalidOwner();
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
        if (_updater == address(0)) revert InvalidUpdater();
        updater = _updater;
        emit SetUpdater(_updater);
    }

    /// @inheritdoc IMetrom
    function setGlobalFee(uint32 _globalFee) external override {
        if (_globalFee > MAX_FEE) revert InvalidGlobalFee();
        if (msg.sender != owner) revert Forbidden();
        globalFee = _globalFee;
        emit SetGlobalFee(_globalFee);
    }

    /// @inheritdoc IMetrom
    function setSpecificFee(address _account, uint32 _specificFee) external override {
        if (_account == address(0)) revert InvalidAccount();
        if (_specificFee > MAX_FEE) revert InvalidSpecificFee();
        if (msg.sender != owner) revert Forbidden();
        specificFee[_account] = SpecificFee({fee: _specificFee, none: _specificFee == 0});
        emit SetSpecificFee(_account, _specificFee);
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
