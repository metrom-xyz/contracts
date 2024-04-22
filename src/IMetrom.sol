pragma solidity >=0.8.0;

struct Reward {
    uint256 amount;
    uint256 unclaimed;
    mapping(address user => uint256 amount) claimed;
}

struct Campaign {
    uint256 chainId;
    address pool;
    uint32 from;
    uint32 to;
    bytes32 specification;
    bytes32 root;
    address[] rewards;
    mapping(address token => Reward) reward;
}

struct ReadonlyReward {
    address token;
    uint256 amount;
    uint256 unclaimed;
}

struct ReadonlyCampaign {
    uint256 chainId;
    address pool;
    uint32 from;
    uint32 to;
    bytes32 specification;
    bytes32 root;
    ReadonlyReward[] rewards;
}

struct CreateBundle {
    uint256 chainId;
    address pool;
    uint32 from;
    uint32 to;
    bytes32 specification;
    address[] rewardTokens;
    uint256[] rewardAmounts;
}

struct DistributeRewardsBundle {
    bytes32 campaignId;
    bytes32 root;
}

struct ClaimRewardsBundle {
    bytes32 campaignId;
    bytes32[] proof;
    address token;
    uint256 amount;
    address receiver;
}

struct CollectFeesBundle {
    address token;
    address receiver;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
interface IMetrom {
    event Initialize(address indexed owner, address updater, uint32 fee, uint32 minimumCampaignDuration);

    event CreateCampaign(
        address indexed owner,
        address indexed pool,
        uint32 from,
        uint32 to,
        bytes32 specification,
        address[] rewardTokens,
        uint256[] rewardAmounts
    );
    event DistributeReward(bytes32 indexed campaignId, bytes32 root);
    event ClaimReward(bytes32 indexed campaignId, address token, uint256 amount, address indexed receiver);
    event CollectFee(address token, uint256 amount, address indexed receiver);

    event TransferOwnership(address indexed owner);
    event AcceptOwnership();

    event SetUpdater(address indexed updater);
    event SetFee(uint32 fee);
    event SetMinimumCampaignDuration(uint32 minimumDuration);

    error CampaignAlreadyExists();
    error Forbidden();
    error InvalidFee();
    error InvalidFrom();
    error InvalidOwner();
    error InvalidPool();
    error InvalidProof();
    error InvalidReceiver();
    error InvalidRewards();
    error InvalidRoot();
    error InvalidTo();
    error InvalidToken();
    error InvalidUpdater();
    error NonExistentCampaign();
    error ZeroAmount();

    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function updater() external view returns (address);
    function fee() external view returns (uint32);
    function minimumCampaignDuration() external view returns (uint32);
    function accruedFees(address token) external returns (uint256);
    function campaignById(bytes32 id) external view returns (ReadonlyCampaign memory);

    function createCampaigns(CreateBundle[] calldata bundles) external;
    function distributeRewards(DistributeRewardsBundle[] calldata bundles) external;
    function claimRewards(ClaimRewardsBundle[] calldata bundles) external;
    function collectFees(CollectFeesBundle[] calldata bundles) external;

    function transferOwnership(address owner) external;
    function acceptOwnership() external;
    function setUpdater(address updater) external;
    function setFee(uint32 fee) external;
    function setMinimumCampaignDuration(uint32 minimumCampaignDuration) external;
}
