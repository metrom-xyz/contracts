/// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.25;

uint256 constant BPS = 10_000;
uint256 constant MAX_FEE = 1_000;

struct MerkleTree {
    bytes32 root;
    bytes32 dataHash;
}

struct Reward {
    address token;
    uint256 amount;
}

struct RewardWithFee {
    address token;
    uint256 amount;
    uint256 fee;
}

struct RewardWithAccounting {
    uint256 amount;
    uint256 unclaimed;
    mapping(address user => uint256 amount) claimed;
}
