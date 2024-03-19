pragma solidity >=0.8.0;

import {RewardWithFee, MerkleTree, Reward} from "../Commons.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
interface IMetromCampaign {
    event Initialize(address creator, bytes32 specificationHash, address feeReceiver, RewardWithFee[] rewards);
    event UpdateTree(bytes32 root, bytes32 dataHash);
    event Claim(address indexed user, address indexed token, uint256 amount);
    event Recover(address indexed receiver, address indexed token, uint256 amount);

    error Forbidden();
    error InvalidCreator();
    error InvalidSpecificationHash();
    error InvalidRewards();
    error InvalidFeeReceiver();
    error InvalidFee();
    error InvalidProof();
    error InvalidReceiver();
    error NothingToRecover();

    function factory() external returns (address);
    function creator() external returns (address);
    function specificationHash() external returns (bytes32);
    function merkleTree() external view returns (MerkleTree memory);
    function claimed(address user, address token) external view returns (uint256);

    function initialize(
        address creator,
        bytes32 specificationHash,
        address feeReceiver,
        uint16 fee,
        Reward[] calldata rewards
    ) external;
    function updateTree(bytes32 root, bytes32 dataHash) external;
    function claim(address[] calldata _tokens, uint16 _weight, bytes32[] calldata proof) external;
    function recover(address token, address receiver) external;
}
