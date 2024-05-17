pragma solidity >=0.8.0;

/// @dev Represents the maximum value for fee percentages (100%).
uint256 constant UNIT = 1_000_000;

/// @dev Represents the maximum allowed fee value (10%).
uint256 constant MAX_FEE = 100_000;

/// @dev Represents the maximum number of different rewards allowed for a
/// single campaign.
uint256 constant MAX_REWARDS_PER_CAMPAIGN = 5;

/// @notice Represents a reward in the contract's state.
/// It keeps track of the original reward amount after fees
/// as well as the unclaimed (remaining) amount and a mapping
/// of claimed amounts for each user.
struct Reward {
    uint256 amount;
    uint256 unclaimed;
    mapping(address user => uint256 amount) claimed;
}

/// @notice Represents an address-specific fee in the contract's state.
/// In particular, if `none` is set to `true` the linked address will have zero
/// fees charged, while if `none` is `false` the contract will take the `fee` value.
/// The double attribute approach lets us understand when a specific fee is actually
/// initialized or not, and if it's not we can fall back to the global fee value.
struct SpecificFee {
    uint32 fee;
    bool none;
}

/// @notice Represents a campaign in the contract's state, with its owner,
/// target chain id, target pool, running period, specification, root and data links,
/// as well as rewards information.
/// A particular note must be made for the `specification` and `data` fields. These can
/// optionally contain a SHA256 hash of some JSON content stored on IPFS such that a CID
/// can be constructed from them. `specification` can point to an IPFS JSON file with
/// additional information/parameters on the campaign, while the `data` field must point
/// to a JSON file containing the raw leaves from which the current campaign's Merkle
/// tree and root was calculated.
struct Campaign {
    address owner;
    address pendingOwner;
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

/// @notice Represents a version of the reward entity that can be used in readonly, getter
/// like functions.
struct ReadonlyReward {
    address token;
    uint256 amount;
    uint256 unclaimed;
}

/// @notice Represents a version of the campaign entity that can be used in readonly, getter
/// like functions.
struct ReadonlyCampaign {
    address owner;
    address pendingOwner;
    uint256 chainId;
    address pool;
    uint32 from;
    uint32 to;
    bytes32 specification;
    bytes32 root;
    ReadonlyReward[] rewards;
}

/// @notice Contains data that can be used by anyone to create a campaign.
struct CreateBundle {
    uint256 chainId;
    address pool;
    uint32 from;
    uint32 to;
    bytes32 specification;
    address[] rewardTokens;
    uint256[] rewardAmounts;
}

/// @notice Contains data that can be used by the current `updater` to distribute rewards
/// on a campaign by specifying a Merkle root and a data link.
struct DistributeRewardsBundle {
    bytes32 campaignId;
    bytes32 root;
    bytes32 data;
}

/// @notice Contains data that can be used by eligible LPs to claim rewards assigned to them
/// on a campaign by specifying data necessary to build a valid Merkle leaf and an inclusion
/// proof.
struct ClaimRewardBundle {
    bytes32 campaignId;
    bytes32[] proof;
    address token;
    uint256 amount;
    address receiver;
}

/// @notice Contains data that can be used by the contract's owner to claim accrued fees.
struct ClaimFeeBundle {
    address token;
    address receiver;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Metrom
/// @notice The contract handling all Metrom entities an interactions. It supports
/// creation and update of campaigns as well as claims and recoveries of unassigned
/// rewards for each one of them.
/// @author Federico Luzzi - <federico.luzzi@metrom.xyz>
interface IMetrom {
    /// @notice Emitted at initialization time.
    /// @param owner The initial contract's owner.
    /// @param updater The initial contract's campaigns updater.
    /// @param globalFee The initial contract's global fee.
    /// @param minimumCampaignDuration The initial contract's minimum campaign duration.
    /// @param maximumCampaignDuration The initial contract's maximum campaign duration.
    event Initialize(
        address indexed owner,
        address updater,
        uint32 globalFee,
        uint32 minimumCampaignDuration,
        uint32 maximumCampaignDuration
    );

    /// @notice Emitted when the contract is ossified.
    event Ossify();

    /// @notice Emitted when a campaign is created.
    /// @param id The id of the campaign.
    /// @param owner The initial owner of the campaign.
    /// @param chainId The targeted chain id of the campaign.
    /// @param pool The targeted pool address of the campaign.
    /// @param from From when the campaign will run.
    /// @param to To when the campaign will run.
    /// @param specification The campaign's specification data hash.
    /// @param rewardTokens A list of the reward token addresses deposited in the campaign.
    /// @param rewardAmounts A list of the after-fees reward token amounts deposited in the campaign.
    /// @param feeAmounts A list of the collected fee amounts amounts collected.
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

    /// @notice Emitted when the updater distributes rewards on a campaign.
    /// @param campaignId The id of the campaign. on which the rewards were distributed.
    /// @param root The updated Merkle root for the campaign.
    /// @param data The updated data content hash for the campaign. This can be used to
    /// contruct an IPFS CID for a file that will contain the raw data used to get the raw
    /// data used to contruct the campaign's Merkle tree and verify the Merkle root.
    event DistributeReward(bytes32 indexed campaignId, bytes32 root, bytes32 data);

    /// @notice Emitted when an eligible LP claims a reward.
    /// @param campaignId The id of the campaign on which the claim is performed.
    /// @param token The claimed token.
    /// @param amount The claimed amount.
    /// @param receiver The claim's receiver.
    event ClaimReward(bytes32 indexed campaignId, address token, uint256 amount, address indexed receiver);

    /// @notice Emitted when the campaign's owner recovers unassigned rewards.
    /// @param campaignId The id of the campaign on which the recovery was performed.
    /// @param token The recovered token.
    /// @param amount The recovered amount.
    /// @param receiver The recovery's receiver.
    event RecoverReward(bytes32 indexed campaignId, address token, uint256 amount, address indexed receiver);

    /// @notice Emitted when Metrom's contract owner claims accrued fees.
    /// @param token The claimed token.
    /// @param amount The claimed amount.
    /// @param receiver The claims's receiver.
    event ClaimFee(address token, uint256 amount, address indexed receiver);

    /// @notice Emitted when a campaign's ownership transfer is initiated.
    /// @param id The targete campaign's id.
    /// @param owner The new desired owner.
    event TransferCampaignOwnership(bytes32 indexed id, address indexed owner);

    /// @notice Emitted when a campaign's current pending owner accepts its ownership.
    /// @param id The targete campaign's id.
    event AcceptCampaignOwnership(bytes32 indexed id);

    /// @notice Emitted when Metrom's ownership transfer is initiated.
    /// @param owner The new desired owner.
    event TransferOwnership(address indexed owner);

    /// @notice Emitted when Metrom's current pending owner accepts its ownership.
    event AcceptOwnership();

    /// @notice Emitted when Metrom's owner sets a new allowed updater address.
    /// @param updater The new updater.
    event SetUpdater(address indexed updater);

    /// @notice Emitted when Metrom's owner sets a new global fee.
    /// @param globalFee The new global fee.
    event SetGlobalFee(uint32 globalFee);

    /// @notice Emitted when Metrom's owner sets a new address-specific fee.
    /// @param account The account for which the specific fee was set.
    /// @param specificFee The new fee.
    event SetSpecificFee(address account, uint32 specificFee);

    /// @notice Emitted when Metrom's owner sets a new minimum campaign duration.
    /// @param minimumCampaignDuration The new minimum campaign duration.
    event SetMinimumCampaignDuration(uint32 minimumCampaignDuration);

    /// @notice Emitted when Metrom's owner sets a new maximum campaign duration.
    /// @param maximumCampaignDuration The new maximum campaign duration.
    event SetMaximumCampaignDuration(uint32 maximumCampaignDuration);

    /// @notice Thrown when trying to create a campaign that already exists.
    error CampaignAlreadyExists();

    /// @notice Thrown when the desired operation's execution is forbidden to the caller.
    error Forbidden();

    /// @notice Thrown when the specified account is invalid while setting a specific fee.
    error InvalidAccount();

    /// @notice Thrown at claim procession time when a 0 amount is specified.
    error InvalidAmount();

    /// @notice Thrown at rewards distribution time when 0-bytes data is specified.
    error InvalidData();

    /// @notice Thrown at campaign creation time when the specified from is in the past.
    error InvalidFrom();

    /// @notice Thrown when the specified global fee goes over the maximum allowed amount.
    error InvalidGlobalFee();

    /// @notice Thrown when the specified maximum campaign duration is less or equal to
    /// the current minimum campaign duration.
    error InvalidMaximumCampaignDuration();

    /// @notice Thrown when the specified minimum campaign duration is greater than or
    /// equal to the current maximum campaign duration.
    error InvalidMinimumCampaignDuration();

    /// @notice Thrown at construction and ownership transfer time when the specified owner
    /// is the zero address.
    error InvalidOwner();

    /// @notice Thrown at campaign creation time when the targeted pool is the zero address.
    error InvalidPool();

    /// @notice Thrown at claim procession time when the provided Merkle proof is invalid.
    error InvalidProof();

    /// @notice Thrown at claim procession time when the provided received is the zero address.
    error InvalidReceiver();

    /// @notice Thrown at campaign creation time when the provided rewards are invalid (either
    /// because there are none, or too many, or because the reward token and reward amount arrays
    /// have inconsistent lengths).
    error InvalidRewards();

    /// @notice Thrown when the specified specific fee goes over the maximum allowed amount.
    error InvalidSpecificFee();

    /// @notice Thrown at rewards distribution time when the specified root is 0-bytes.
    error InvalidRoot();

    /// @notice Thrown at campaign creation time either when the specified to timestamp comes
    ///  before the specified from timestamp or when it results in an invalid campaign duration
    ///  according to the current minimum and maximum allowed values.
    error InvalidTo();

    /// @notice Thrown at claim procession time when the provided token is the zero address.
    error InvalidToken();

    /// @notice Thrown updater update time when the provided address is the zero address.
    error InvalidUpdater();

    /// @notice Thrown when a campaign that was required to exists does not exist.
    error NonExistentCampaign();

    /// @notice Thrown when trying to upgrade the contract while ossified.
    error Ossified();

    /// @notice Thrown at claim procession time when the requested claim amount is 0.
    error ZeroAmount();

    /// @notice Initializes the contract.
    /// @param owner The initial owner.
    /// @param updater The initial updater.
    /// @param updater The initial global fee.
    /// @param updater The initial minimum campaign duration.
    /// @param updater The initial maximum campaign duration.
    function initialize(
        address owner,
        address updater,
        uint32 globalFee,
        uint32 minimumCampaignDuration,
        uint32 maximumCampaignDuration
    ) external;

    /// @notice Returns whether the contract is upgradeable or not.
    /// @return ossified The upgradeability state of the contract.
    function ossified() external returns (bool ossified);

    /// @notice Makes the contract immutable, de-facto disallowing
    /// any future upgrade. Can only be called by Metrom's owner.
    function ossify() external;

    /// @notice Returns the current owner.
    /// @return owner The current owner.
    function owner() external view returns (address owner);

    /// @notice Returns the current pending owner.
    /// @return pendingOwner The current pending owner.
    function pendingOwner() external view returns (address pendingOwner);

    /// @notice Returns the currently allowed updater.
    /// @return updater The currently allowed updater.
    function updater() external view returns (address updater);

    /// @notice Returns the current global fee.
    /// @return globalFee The current global fee.
    function globalFee() external view returns (uint32 globalFee);

    /// @notice Returns the current specific fee value for a provided account.
    /// @param account The account for which to fetch the fee value.
    /// @return specificFee The specific fee for the provided account.
    function specificFeeFor(address account) external view returns (SpecificFee memory specificFee);

    /// @notice Returns the currently enforced minimum campaign duration.
    /// @return minimumCampaignDuration The currently enforced minimum campaign duration.
    function minimumCampaignDuration() external view returns (uint32 minimumCampaignDuration);

    /// @notice Returns the currently enforced minimum campaign duration.
    /// @return maximumCampaignDuration The currently enforced minimum campaign duration.
    function maximumCampaignDuration() external view returns (uint32 maximumCampaignDuration);

    /// @notice Returns the currently claimable fees amount for a specified token.
    /// @param token The token for which to fetch the currently claimable amount.
    /// @return claimable The amount of the specified token that is currently claimable.
    function claimableFees(address token) external returns (uint256 claimable);

    /// @notice Returns a campaign in readonly format.
    /// @param id The wanted campaign id.
    /// @return campaign The campaign in readonly format.
    function campaignById(bytes32 id) external view returns (ReadonlyCampaign memory campaign);

    /// @notice Creates one or more campaigns. The transaction will revert even if one
    /// of the specified bundles results in a creation failure (all or none).
    /// @param bundles The bundles containing the data used to create the campaigns.
    function createCampaigns(CreateBundle[] calldata bundles) external;

    /// @notice Distributes rewards on one or more campaigns. The transaction will revert
    /// even if only one of the specified bundles results in a distribution failure (all or none).
    /// @param bundles The bundles containing the data used to distribute the rewards.
    function distributeRewards(DistributeRewardsBundle[] calldata bundles) external;

    /// @notice Claims outstanding rewards on one or more campaigns. The transaction will revert
    /// even if only one of the specified bundles results in a claim failure (all or none).
    /// @param bundles The bundles containing the data used to claim the rewards.
    function claimRewards(ClaimRewardBundle[] calldata bundles) external;

    /// @notice Can be used by a campaign owner to recover unassigned rewards on one or more
    /// campaigns. The transaction will revert even if only one of the specified bundles results
    /// in a recovery failure (all or none).
    /// @param bundles The bundles containing the data used to claim the recoverable rewards.
    function recoverRewards(ClaimRewardBundle[] calldata bundles) external;

    /// @notice Returns the current owner of a campaign.
    /// @param id The id of the targeted campaign.
    /// @return owner The current owner of the campaign.
    function campaignOwner(bytes32 id) external view returns (address owner);

    /// @notice Returns the current pending owner of a campaign.
    /// @param id The id of the targeted campaign.
    /// @return pendingOwner The current pending owner of the campaign.
    function campaignPendingOwner(bytes32 id) external view returns (address pendingOwner);

    /// @notice Initiates an ownership transfer operation for a campaign. This can only be
    /// called by the current campaign owner.
    /// @param id The id of the targeted campaign.
    /// @param owner The desired new owner of the campaign.
    function transferCampaignOwnership(bytes32 id, address owner) external;

    /// @notice Finalized an ownership transfer operation for a campaign. This can only be
    /// called by the current campaign pending owner to accept ownership of it.
    /// @param id The id of the targeted campaign.
    function acceptCampaignOwnership(bytes32 id) external;

    /// @notice Initiates an ownership transfer operation for the Metrom contract. This can
    /// only be called by the current Metrom owner.
    /// @param owner The desired new owner of Metrom.
    function transferOwnership(address owner) external;

    /// @notice Finalizes an ownership transfer operation for the Metrom contract. This can
    /// only be called by the current Metrom pending owner.
    function acceptOwnership() external;

    /// @notice Can be called by Metrom's owner to claim one or more outstanding fees.
    /// @param bundles The bundles containing the data used to claim the fees.
    function claimFees(ClaimFeeBundle[] calldata bundles) external;

    /// @notice Can be called by Metrom's owner to set a new allowed updater address.
    function setUpdater(address updater) external;

    /// @notice Can be called by Metrom's owner to set a new global fee value.
    function setGlobalFee(uint32 fee) external;

    /// @notice Can be called by Metrom's owner to set a new specific fee value for an
    /// account.
    /// @param account The account for which to set the specific fee value.
    /// @param fee The specific fee value.
    function setSpecificFee(address account, uint32 fee) external;

    /// @notice Can be called by Metrom's owner to set a new minimum allowed campaign duration.
    /// @param minimumCampaignDuration The new minimum allowed campaign duration.
    function setMinimumCampaignDuration(uint32 minimumCampaignDuration) external;

    /// @notice Can be called by Metrom's owner to set a new maximum allowed campaign duration.
    /// @param maximumCampaignDuration The new maximum allowed campaign duration.
    function setMaximumCampaignDuration(uint32 maximumCampaignDuration) external;
}
