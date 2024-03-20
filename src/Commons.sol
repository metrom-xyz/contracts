/// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.25;

// maximum unit that percentages can take
uint256 constant UNIT = 1_000_000;

// max fee is 10%
uint256 constant MAX_FEE = 100_000;

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
    uint256 remaining;
    mapping(address user => uint256 amount) claimed;
}
