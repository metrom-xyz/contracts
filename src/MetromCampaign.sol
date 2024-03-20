pragma solidity 0.8.25;

import {Initializable} from "oz/proxy/utils/Initializable.sol";
import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "oz/utils/ReentrancyGuard.sol";
import {MerkleProof} from "oz/utils/cryptography/MerkleProof.sol";

import {UNIT, MAX_FEE, TokenAmount} from "./Commons.sol";
import {IMetromCampaign, Reward, RewardWithFee, InitializeCampaignParams} from "./interfaces/IMetromCampaign.sol";
import {IMetromCampaignFactory} from "./interfaces/IMetromCampaignFactory.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract MetromCampaign is Initializable, IMetromCampaign, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public override owner;
    address public override pendingOwner;
    address public override factory;
    address public override pool;
    uint32 public override from;
    uint32 public override to;
    bytes32 public override treeRoot;
    bytes32 public override dataHash;
    mapping(address token => Reward) reward;

    constructor() {
        _disableInitializers();
    }

    function initialize(InitializeCampaignParams calldata _params) external override initializer {
        if (_params.owner == address(0)) revert InvalidOwner();
        if (_params.feeReceiver == address(0)) revert InvalidFeeReceiver();
        if (_params.fee > MAX_FEE) revert InvalidFee();
        if (_params.pool == address(0)) revert InvalidPool();
        if (_params.from < block.timestamp) revert InvalidFrom();
        if (_params.to <= _params.from) revert InvalidTo();
        if (_params.rewards.length == 0 || _params.rewards.length > 5) revert InvalidRewards();

        owner = _params.owner;
        factory = msg.sender;
        pool = _params.pool;
        from = _params.from;
        to = _params.to;

        RewardWithFee[] memory _rewardsWithFee = new RewardWithFee[](_params.rewards.length);
        for (uint8 _i = 0; _i < _params.rewards.length; _i++) {
            TokenAmount memory _reward = _params.rewards[_i];
            if (_reward.token == address(0)) revert InvalidRewards();
            if (_reward.amount == 0) revert InvalidRewards();
            for (uint8 _j = _i + 1; _j < _params.rewards.length; _j++) {
                if (_reward.token == _params.rewards[_j].token) revert InvalidRewards();
            }
            reward[_reward.token].amount = _reward.amount;
            reward[_reward.token].remaining = _reward.amount;
            uint256 _rewardFee = (_reward.amount * _params.fee) / UNIT;
            uint256 _rewardAmountPlusFees;
            unchecked {
                _rewardAmountPlusFees = _reward.amount + _rewardFee;
            }
            IERC20(_reward.token).safeTransferFrom(_params.owner, address(this), _rewardAmountPlusFees);
            if (_rewardFee > 0) IERC20(_reward.token).safeTransfer(_params.feeReceiver, _rewardFee);
            _rewardsWithFee[_i] = RewardWithFee({token: _reward.token, amount: _reward.amount, fee: _rewardFee});
        }

        emit Initialize(_params.owner, _params.pool, _params.from, _params.to, _params.feeReceiver, _rewardsWithFee);
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

    function updateTree(bytes32 _treeRoot, bytes32 _dataHash) external override {
        if (msg.sender != IMetromCampaignFactory(factory).updater()) revert Forbidden();
        treeRoot = _treeRoot;
        dataHash = _dataHash;
        emit UpdateTree(_treeRoot, _dataHash);
    }

    function claim(address[] calldata _tokens, uint32 _weight, bytes32[] calldata _proof) external nonReentrant {
        bytes32 _leaf = keccak256(abi.encode(msg.sender, _weight));
        if (!MerkleProof.verifyCalldata(_proof, treeRoot, _leaf)) revert InvalidProof();

        for (uint256 _i; _i < _tokens.length; _i++) {
            address _token = _tokens[_i];
            Reward storage _reward = reward[_token];
            uint256 _claimed = (_reward.amount * _weight / UNIT) - _reward.claimed[msg.sender];
            _reward.remaining -= _claimed;
            _reward.claimed[msg.sender] += _claimed;
            IERC20(_token).safeTransfer(msg.sender, _claimed);
            emit Claim(msg.sender, _token, _claimed);
        }
    }

    function recover(address _token, address _receiver) external override {
        if (_receiver == address(0)) revert InvalidReceiver();
        if (msg.sender != owner) revert Forbidden();
        uint256 _reimbursement = IERC20(_token).balanceOf(address(this));
        unchecked {
            _reimbursement -= reward[_token].remaining;
        }
        if (_reimbursement == 0) revert NothingToRecover();
        IERC20(_token).safeTransfer(_receiver, _reimbursement);
        emit Recover(_receiver, _token, _reimbursement);
    }

    function claimed(address _token, address _user) external view override returns (uint256) {
        return reward[_token].claimed[_user];
    }
}
