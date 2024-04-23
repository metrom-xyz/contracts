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
    bytes32 data;
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
    bytes32 data;
}

struct ClaimRewardBundle {
    bytes32 campaignId;
    bytes32[] proof;
    address token;
    uint256 amount;
    address receiver;
}

struct ClaimFeeBundle {
    address token;
    address receiver;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
interface IMetrom {
    event Initialize(address indexed owner, address updater, uint32 fee, uint32 minimumCampaignDuration);

    event CreateCampaign(
        bytes32 indexed id,
        address indexed owner,
        uint256 chainId,
        address pool,
        uint32 from,
        uint32 to,
        bytes32 specification,
        address[] rewardTokens,
        uint256[] rewardAmounts,
        uint256[] feeAmounts
    );
    event DistributeReward(bytes32 indexed campaignId, bytes32 root, bytes32 data);
    event ClaimReward(bytes32 indexed campaignId, address token, uint256 amount, address indexed receiver);
    event ClaimFee(address token, uint256 amount, address indexed receiver);

    event TransferOwnership(address indexed owner);
    event AcceptOwnership();

    event SetUpdater(address indexed updater);
    event SetFee(uint32 fee);
    event SetMinimumCampaignDuration(uint32 minimumDuration);

    error CampaignAlreadyExists();
    error Forbidden();
    error InvalidData();
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
    function claimableFees(address token) external returns (uint256);
    function campaignById(bytes32 id) external view returns (ReadonlyCampaign memory);

    function createCampaigns(CreateBundle[] calldata bundles) external;
    function distributeRewards(DistributeRewardsBundle[] calldata bundles) external;
    function claimRewards(ClaimRewardBundle[] calldata bundles) external;

    function transferOwnership(address owner) external;
    function acceptOwnership() external;
    function claimFees(ClaimFeeBundle[] calldata bundles) external;
    function setUpdater(address updater) external;
    function setFee(uint32 fee) external;
    function setMinimumCampaignDuration(uint32 minimumCampaignDuration) external;
}
