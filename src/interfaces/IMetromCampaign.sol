pragma solidity >=0.8.0;

import {TokenAmount} from "../Commons.sol";

struct InitializeCampaignParams {
    address owner;
    address feeReceiver;
    address pool;
    uint32 fee;
    uint32 from;
    uint32 to;
    TokenAmount[] rewards;
}

struct RewardWithFee {
    address token;
    uint256 amount;
    uint256 fee;
}

struct Reward {
    uint256 amount;
    uint256 remaining;
    mapping(address user => uint256 amount) claimed;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
interface IMetromCampaign {
    event Initialize(
        address indexed owner,
        address indexed pool,
        uint32 from,
        uint32 to,
        address feeReceiver,
        RewardWithFee[] rewards
    );
    event TransferOwnership(address indexed owner);
    event AcceptOwnership();
    event UpdateTree(bytes32 root, bytes32 dataHash);
    event Claim(address indexed user, address indexed token, uint256 amount);
    event Recover(address indexed receiver, address indexed token, uint256 amount);

    error Forbidden();
    error InvalidOwner();
    error InvalidFeeReceiver();
    error InvalidFee();
    error InvalidPool();
    error InvalidFrom();
    error InvalidTo();
    error InvalidRewards();
    error InvalidProof();
    error InvalidReceiver();
    error NothingToRecover();

    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function from() external view returns (uint32);
    function to() external view returns (uint32);
    function pool() external view returns (address);
    function factory() external view returns (address);
    function dataHash() external view returns (bytes32);
    function treeRoot() external view returns (bytes32);
    function claimed(address user, address token) external view returns (uint256);

    function transferOwnership(address owner) external;
    function acceptOwnership() external;
    function initialize(InitializeCampaignParams calldata params) external;
    function updateTree(bytes32 root, bytes32 dataHash) external;
    function claim(address[] calldata _tokens, uint32 _weight, bytes32[] calldata proof) external;
    function recover(address token, address receiver) external;
}
