pragma solidity 0.8.25;

import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "oz/utils/cryptography/MerkleProof.sol";
import {console2} from "forge-std/console2.sol";

import {
    IMetrom,
    Campaign,
    Reward,
    ReadonlyCampaign,
    ReadonlyReward,
    CreateBundle,
    DistributeRewardsBundle,
    ClaimRewardsBundle,
    CollectFeesBundle
} from "./IMetrom.sol";

uint256 constant UNIT = 1_000_000;
uint256 constant MAX_FEE = 100_000;
uint256 constant MAX_REWARDS_PER_CAMPAIGN = 5;

/// SPDX-License-Identifier: GPL-3.0-or-later
contract Metrom is IMetrom {
    using SafeERC20 for IERC20;

    address public override owner;
    address public override pendingOwner;
    address public override updater;
    uint32 public override fee;
    uint32 public override minimumCampaignDuration;
    mapping(bytes32 id => Campaign) internal campaigns;
    mapping(address token => uint256 amount) public override accruedFees;

    constructor(address _owner, address _updater, uint32 _fee, uint32 _minimumCampaignDuration) {
        if (_owner == address(0)) revert InvalidOwner();
        if (_updater == address(0)) revert InvalidUpdater();
        if (_fee > MAX_FEE) revert InvalidFee();

        owner = _owner;
        updater = _updater;
        minimumCampaignDuration = _minimumCampaignDuration;
        fee = _fee;

        emit Initialize(_owner, _updater, _fee, _minimumCampaignDuration);
    }

    function _campaignId(CreateBundle memory _bundle) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
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
            chainId: campaign.chainId,
            pool: campaign.pool,
            from: campaign.from,
            to: campaign.to,
            specification: campaign.specification,
            root: campaign.root,
            rewards: _rewards
        });
    }

    function createCampaigns(CreateBundle[] calldata _bundles) external {
        uint32 _fee = fee;
        uint32 _minimumCampaignDuration = minimumCampaignDuration;

        for (uint256 _i = 0; _i < _bundles.length; _i++) {
            CreateBundle memory _bundle = _bundles[_i];

            if (_bundle.pool == address(0)) revert InvalidPool();
            if (_bundle.from <= block.timestamp) revert InvalidFrom();
            if (_bundle.to <= _bundle.from + _minimumCampaignDuration) revert InvalidTo();
            if (
                _bundle.rewardTokens.length == 0 || _bundle.rewardTokens.length > MAX_REWARDS_PER_CAMPAIGN
                    || _bundle.rewardTokens.length != _bundle.rewardAmounts.length
            ) revert InvalidRewards();

            bytes32 _id = _campaignId(_bundle);
            Campaign storage campaign = campaigns[_id];
            if (campaign.from != 0) revert CampaignAlreadyExists();

            campaign.chainId = _bundle.chainId;
            campaign.pool = _bundle.pool;
            campaign.from = _bundle.from;
            campaign.to = _bundle.to;
            campaign.specification = _bundle.specification;
            campaign.rewards = _bundle.rewardTokens;

            uint256[] memory _feeAmounts = new uint256[](_bundle.rewardTokens.length);
            for (uint256 _j = 0; _j < _bundle.rewardTokens.length; _j++) {
                address _token = _bundle.rewardTokens[_j];
                if (_token == address(0)) revert InvalidRewards();

                uint256 _amount = _bundle.rewardAmounts[_j];
                if (_amount == 0) revert InvalidRewards();

                for (uint256 _k = _j + 1; _k < _bundle.rewardTokens.length; _k++) {
                    if (_token == _bundle.rewardTokens[_k]) revert InvalidRewards();
                }

                Reward storage reward = campaign.reward[_token];
                reward.amount = _amount;
                reward.unclaimed = _amount;

                uint256 _feeAmount = _amount * _fee / UNIT;
                uint256 _rewardAmountPlusFees = _amount + _feeAmount;
                accruedFees[_token] += _feeAmount;
                _feeAmounts[_j] = _feeAmount;

                IERC20(_token).safeTransferFrom(msg.sender, address(this), _rewardAmountPlusFees);
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
                _bundle.rewardAmounts,
                _feeAmounts
            );
        }
    }

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

    function claimRewards(ClaimRewardsBundle[] calldata _bundles) external override {
        for (uint256 _i; _i < _bundles.length; _i++) {
            ClaimRewardsBundle calldata _bundle = _bundles[_i];
            if (_bundle.token == address(0)) revert InvalidToken();
            if (_bundle.amount == 0) revert ZeroAmount();

            Campaign storage campaign = _getExistingCampaign(_bundle.campaignId);

            bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, _bundle.token, _bundle.amount));
            if (!MerkleProof.verifyCalldata(_bundle.proof, campaign.root, _leaf)) revert InvalidProof();

            Reward storage reward = campaign.reward[_bundle.token];
            uint256 _claimedAmount = _bundle.amount - reward.claimed[msg.sender];
            reward.unclaimed -= _claimedAmount;

            IERC20(_bundle.token).safeTransfer(_bundle.receiver, _claimedAmount);

            emit ClaimReward(_bundle.campaignId, _bundle.token, _claimedAmount, _bundle.receiver);
        }
    }

    function collectFees(CollectFeesBundle[] calldata _bundles) external {
        if (msg.sender != owner) revert Forbidden();

        for (uint256 _i = 0; _i < _bundles.length; _i++) {
            CollectFeesBundle calldata _bundle = _bundles[_i];

            if (_bundle.token == address(0)) revert InvalidToken();
            if (_bundle.receiver == address(0)) revert InvalidReceiver();

            uint256 _claimAmount = accruedFees[_bundle.token];
            if (_claimAmount == 0) revert ZeroAmount();

            delete accruedFees[_bundle.token];
            IERC20(_bundle.token).safeTransfer(_bundle.receiver, _claimAmount);
            emit CollectFee(_bundle.token, _claimAmount, _bundle.receiver);
        }
    }

    function transferOwnership(address _owner) external override {
        if (msg.sender != owner) revert Forbidden();
        pendingOwner = _owner;
        emit TransferOwnership(_owner);
    }

    function acceptOwnership() external override {
        if (msg.sender != pendingOwner) revert Forbidden();
        delete pendingOwner;
        owner = msg.sender;
        emit AcceptOwnership();
    }

    function setUpdater(address _updater) external override {
        if (msg.sender != owner) revert Forbidden();
        if (_updater == address(0)) revert InvalidUpdater();
        updater = _updater;
        emit SetUpdater(_updater);
    }

    function setFee(uint32 _fee) external override {
        if (msg.sender != owner) revert Forbidden();
        if (_fee > MAX_FEE) revert InvalidFee();
        fee = _fee;
        emit SetFee(_fee);
    }

    function setMinimumCampaignDuration(uint32 _minimumCampaignDuration) external override {
        if (msg.sender != owner) revert Forbidden();
        minimumCampaignDuration = _minimumCampaignDuration;
        emit SetMinimumCampaignDuration(_minimumCampaignDuration);
    }
}
