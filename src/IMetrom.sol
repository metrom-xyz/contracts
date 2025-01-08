pragma solidity >=0.8.0;

/// @dev Represents the maximum value for fee percentages (100%).
uint32 constant UNIT = 1_000_000;

/// @notice Represents a reward in the contract's state.
/// It keeps track of the remaining amount after fees
/// as well as a mapping of claimed amounts for each user.
struct Reward {
    uint256 amount;
    mapping(address user => uint256 amount) claimed;
}

/// @notice Represents a rewards based campaign in the contract's state, with its owner,
/// target pool, running period, specification hash, root and data hash links, as well
/// as rewards information. A particular note must be made for the `specificationHash` and
/// `data` fields. These can optionally contain a SHA256 hash of some JSON content stored
/// on IPFS such that a CID can be constructed from them. `specificationHash` can point
/// to an IPFS JSON file with additional information/parameters on the campaign, while
/// the `data` field must point to a JSON file containing the raw leaves from which the
/// current campaign's Merkle tree and root was calculated.
struct RewardsCampaignV1 {
    address owner;
    address pendingOwner;
    address pool;
    uint32 from;
    uint32 to;
    bytes32 specificationHash;
    bytes32 dataHash;
    bytes32 root;
    mapping(address token => Reward) reward;
}

/// @notice Represents a points based campaign in the contract's state, with its owner,
/// target pool, running period, specification hash and root, as well as points information.
/// A particular note must be made for the `specificationHash` field. This can optionally
/// contain a SHA256 hash of some JSON content stored on IPFS such that a CID can be
/// constructed from it. `specificationHash` can point to an IPFS JSON file with additional
/// information/parameters on the campaign.
struct PointsCampaignV1 {
    address owner;
    address pendingOwner;
    address pool;
    uint32 from;
    uint32 to;
    bytes32 specificationHash;
    uint256 points;
}

/// @notice Represents a rewards based campaign in the contract's state, with its owner,
/// running period, type, data, specification hash, root and data hash links, as well as rewards
/// information. A particular note must be made for the `specificationHash` and `dataHash` fields.
/// These can optionally contain a SHA256 hash of some JSON content stored on IPFS such that
/// a CID can be constructed from them. `specificationHash` can point to an IPFS JSON file with
/// additional information/parameters on the campaign, while the `data` field must point
/// to a JSON file containing the raw leaves from which the current campaign's Merkle
/// tree and root was calculated.
struct RewardsCampaignV2 {
    address owner;
    address pendingOwner;
    uint32 from;
    uint32 to;
    uint32 kind;
    bytes data;
    bytes32 specificationHash;
    bytes32 dataHash;
    bytes32 root;
    mapping(address token => Reward) reward;
}

/// @notice Represents a points based campaign in the contract's state, with its owner,
/// running period, type, data, specification hash, root and points information.
/// A particular note must be made for the `specificationHash` field. This can optionally
/// contain a SHA256 hash of some JSON content stored on IPFS such that a CID can be
/// constructed from it. `specificationHash` can point to an IPFS JSON file with additional
/// information/parameters on the campaign.
struct PointsCampaignV2 {
    address owner;
    address pendingOwner;
    uint32 from;
    uint32 to;
    uint32 kind;
    bytes data;
    bytes32 specificationHash;
    uint256 points;
}

/// @notice Represents a readonly rewards based campaign.
struct ReadonlyRewardsCampaign {
    address owner;
    address pendingOwner;
    uint32 from;
    uint32 to;
    uint32 kind;
    bytes data;
    bytes32 specificationHash;
    bytes32 dataHash;
    bytes32 root;
}

/// @notice Represents a readonly points based campaign
struct ReadonlyPointsCampaign {
    address owner;
    address pendingOwner;
    uint32 from;
    uint32 to;
    uint32 kind;
    bytes data;
    bytes32 specificationHash;
    uint256 points;
}

struct RewardAmount {
    address token;
    uint256 amount;
}

struct CreatedCampaignReward {
    address token;
    uint256 amount;
    uint256 fee;
}

/// @notice Contains data that can be used by anyone to create a rewards based campaign.
struct CreateRewardsCampaignBundle {
    uint32 from;
    uint32 to;
    uint32 kind;
    bytes data;
    bytes32 specificationHash;
    RewardAmount[] rewards;
}

/// @notice Contains data that can be used by anyone to create a points based campaign.
struct CreatePointsCampaignBundle {
    uint32 from;
    uint32 to;
    uint32 kind;
    bytes data;
    bytes32 specificationHash;
    uint256 points;
    address feeToken;
}

/// @notice Contains data that can be used by the current `updater` to
/// distribute rewards on a campaign by specifying a Merkle root and a data link.
struct DistributeRewardsBundle {
    bytes32 campaignId;
    bytes32 root;
    bytes32 dataHash;
}

/// @notice Contains data that can be used by the current `updater` or the
/// `owner` to update the minimum required rate to be emitted in a campaign for
/// a certain reward token or the minimum fee token rate.
struct SetMinimumTokenRateBundle {
    address token;
    uint256 minimumRate;
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
/// @notice The interface for the contract handling all Metrom entities and interactions.
/// It supports creation and update of campaigns as well as claims and recoveries of unassigned
/// rewards for each one of them.
/// @author Federico Luzzi - <federico.luzzi@metrom.xyz>
interface IMetrom {
    /// @notice Emitted at initialization time.
    /// @param owner The initial contract's owner.
    /// @param updater The initial contract's updater.
    /// @param fee The initial contract's rewards campaign fee.
    /// @param minimumCampaignDuration The initial contract's minimum campaign duration.
    /// @param maximumCampaignDuration The initial contract's maximum campaign duration.
    event Initialize(
        address indexed owner,
        address updater,
        uint32 fee,
        uint32 minimumCampaignDuration,
        uint32 maximumCampaignDuration
    );

    /// @notice Emitted when the contract is ossified.
    event Ossify();

    /// @notice Emitted when a rewards based campaign is created.
    /// @param id The id of the campaign.
    /// @param owner The initial owner of the campaign.
    /// @param from From when the campaign will run.
    /// @param to To when the campaign will run.
    /// @param kind The campaign's kind.
    /// @param data ABI-encoded campaign-specific data.
    /// @param specificationHash The campaign's specification hash.
    /// @param rewards A list of the reward tokens deposited in the campaign. Each list
    /// item contains the used reward token address along with the after-fee amount and
    /// the fee amount paid.
    event CreateRewardsCampaign(
        bytes32 indexed id,
        address indexed owner,
        uint32 from,
        uint32 to,
        uint32 kind,
        bytes data,
        bytes32 specificationHash,
        CreatedCampaignReward[] rewards
    );

    /// @notice Emitted when a points based campaign is created.
    /// @param id The id of the campaign.
    /// @param owner The initial owner of the campaign.
    /// @param from From when the campaign will run.
    /// @param to To when the campaign will run.
    /// @param kind The campaign's kind.
    /// @param data ABI-encoded campaign-specific data.
    /// @param specificationHash The campaign's specification data hash.
    /// @param points The amount of points to distribute (scaled to account for 18 decimals).
    /// @param feeToken The token used to pay the creation fee.
    /// @param fee The creation fee amount.
    event CreatePointsCampaign(
        bytes32 indexed id,
        address indexed owner,
        uint32 from,
        uint32 to,
        uint32 kind,
        bytes data,
        bytes32 specificationHash,
        uint256 points,
        address feeToken,
        uint256 fee
    );

    /// @notice Emitted when the campaigns updater distributes rewards on a campaign.
    /// @param campaignId The id of the campaign. on which the rewards were distributed.
    /// @param root The updated Merkle root for the campaign.
    /// @param data The updated data content hash for the campaign. This can be used to
    /// contruct an IPFS CID for a file that will contain the raw data used to get the raw
    /// data used to contruct the campaign's Merkle tree and verify the Merkle root.
    event DistributeReward(bytes32 indexed campaignId, bytes32 root, bytes32 data);

    /// @notice Emitted when the rates updater or the owner updates the minimum emission
    /// rate of a certain whitelisted reward token required in order to create a rewards based
    /// campaign.
    /// @param token The address of the whitelisted reward token to update.
    /// @param minimumRate The new minimum rate required in order to create a
    /// campaign.
    event SetMinimumRewardTokenRate(address indexed token, uint256 minimumRate);

    /// @notice Emitted when the rates updater or the owner updates the minimum rate for a
    /// certain whitelisted fee token required in order to create a points based campaign.
    /// @param token The address of the whitelisted fee token to update.
    /// @param minimumRate The new minimum rate required in order to create a
    /// campaign.
    event SetMinimumFeeTokenRate(address indexed token, uint256 minimumRate);

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
    /// @param owner The targete campaign's new owner.
    event AcceptCampaignOwnership(bytes32 indexed id, address indexed owner);

    /// @notice Emitted when Metrom's ownership transfer is initiated.
    /// @param owner The new desired owner.
    event TransferOwnership(address indexed owner);

    /// @notice Emitted when Metrom's current pending owner accepts its ownership.
    /// @param owner The new owner.
    event AcceptOwnership(address indexed owner);

    /// @notice Emitted when Metrom's owner sets a new allowed updater address.
    /// @param updater The new updater.
    event SetUpdater(address indexed updater);

    /// @notice Emitted when Metrom's owner sets a new rewards based campaign fee.
    /// @param fee The new rewards campaign fee.
    event SetFee(uint32 fee);

    /// @notice Emitted when Metrom's owner sets a new address-specific
    /// rebate for the protocol rewards based campaign fees.
    /// @param account The account for which the rebate was set.
    /// @param rebate The rebate.
    event SetFeeRebate(address account, uint32 rebate);

    /// @notice Emitted when Metrom's owner sets a new minimum campaign duration.
    /// @param minimumCampaignDuration The new minimum campaign duration.
    event SetMinimumCampaignDuration(uint32 minimumCampaignDuration);

    /// @notice Emitted when Metrom's owner sets a new maximum campaign duration.
    /// @param maximumCampaignDuration The new maximum campaign duration.
    event SetMaximumCampaignDuration(uint32 maximumCampaignDuration);

    /// @notice Thrown when trying to create a campaign that already exists.
    error AlreadyExists();

    /// @notice Thrown when trying to create a campaign with a non-whitelisted reward token.
    error DisallowedRewardToken();

    /// @notice Thrown when trying to create a campaign with a duration that is too long.
    error DurationTooLong();

    /// @notice Thrown when trying to create a campaign with a duration that is too short.
    error DurationTooShort();

    /// @notice Thrown when the desired operation's execution is forbidden to the caller.
    error Forbidden();

    /// @notice Thrown when the specified fee goes over the maximum allowed amount.
    error InvalidFee();

    /// @notice Thrown when the specified maximum campaign duration is less or equal to
    /// the current minimum campaign duration.
    error InvalidMaximumCampaignDuration();

    /// @notice Thrown when the specified minimum campaign duration is greater than or
    /// equal to the current maximum campaign duration.
    error InvalidMinimumCampaignDuration();

    /// @notice Thrown at claim procession time when the provided Merkle proof is invalid.
    error InvalidProof();

    /// @notice Thrown when creating a points based campaign if a zero points amount was specified.
    error NoPoints();

    /// @notice Thrown when creating a campaign if no rewards were specified.
    error NoRewards();

    /// @notice Thrown when a campaign that was required to exists does not exist.
    error NonExistentCampaign();

    /// @notice Thrown when a campaign reward that was required to exists does not exist.
    error NonExistentReward();

    /// @notice Thrown when trying to upgrade the contract while ossified.
    error Ossified();

    /// @notice Thrown when trying to set a fee rebate that is too high.
    error RebateTooHigh();

    /// @notice Thrown when trying to create a campaign when the specified reward amount is too low.
    error RewardAmountTooLow();

    /// @notice Thrown when trying to create a campaign with a from timestamp in the past.
    error StartTimeInThePast();

    /// @notice Thrown when trying to create a campaign when too many rewards are specified.
    error TooManyRewards();

    /// @notice Thrown when trying to claim a reward that is too much to be claimed.
    error TooMuchClaimedAmount();

    /// @notice Thrown when trying to set the updater to the zero address.
    error ZeroAddressUpdater();

    /// @notice Thrown when trying to set the fee rebate for a zero address account.
    error ZeroAddressAccount();

    /// @notice Thrown when trying to transfer Metrom's or a campaign's ownership to the zero address.
    error ZeroAddressOwner();

    /// @notice Thrown when processing a claim with a zero address receiver or when claiming
    /// fees for a zero address receiver.
    error ZeroAddressReceiver();

    /// @notice Thrown when trying to create a points based campaign with a zero address fee token.
    error ZeroAddressFeeToken();

    /// @notice Thrown when trying to create a points based campaign with a disallowed fee token.
    error DisallowedFeeToken();

    /// @notice Thrown when trying to create a points based campaign with a non adequate fee.
    error FeeAmountTooLow();

    /// @notice Thrown when trying to create a campaign with a zero address reward token or
    /// when trying to set the minimum reward token rate for a zero address reward token.
    error ZeroAddressRewardToken();

    /// @notice Thrown at claim processing time when the requested claim amount is 0.
    error ZeroAmount();

    /// @notice Thrown at rewards distribution time when 0-bytes data is specified.
    error ZeroData();

    /// @notice Thrown when trying to create a campaign with a zero reward amount.
    error ZeroRewardAmount();

    /// @notice Thrown at rewards distribution time when the specified root is 0-bytes.
    error ZeroRoot();

    /// @notice Initializes the contract.
    /// @param owner The initial owner.
    /// @param updater The initial updater.
    /// @param fee The initial fee.
    /// @param minimumCampaignDuration The initial minimum campaign duration.
    /// @param maximumCampaignDuration The initial maximum campaign duration.
    function initialize(
        address owner,
        address updater,
        uint32 fee,
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

    /// @notice Returns the current fee.
    /// @return fee The current fee.
    function fee() external view returns (uint32 fee);

    /// @notice Returns the current fee rebate for a provided account.
    /// @param account The account for which to fetch the fee rebate.
    /// @return rebate The fee rebate for the provided account.
    function feeRebate(address account) external view returns (uint32 rebate);

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

    /// @notice Returns the minimum emission rate required in order to create a
    /// campaign with the passed token. Returns 0 if the token is not whitelisted and it
    /// cannot be used to create a campaign.
    /// @param token The reward token's address.
    /// @return minimumRate The reward token's minimum required emission rate.
    function minimumRewardTokenRate(address token) external view returns (uint256 minimumRate);

    /// @notice Returns the minimum fee token rate required in order to create a
    /// points-based campaign with the given token. Returns 0 if the token is not
    /// whitelisted and it cannot be used to create a campaign.
    /// @param token The fee token's address.
    /// @return minimumRate The reward token's minimum required rate.
    function minimumFeeTokenRate(address token) external view returns (uint256 minimumRate);

    /// @notice Returns a points based campaign in readonly format.
    /// @param id The wanted campaign id.
    /// @return campaign The points based campaign in readonly format.
    function pointsCampaignById(bytes32 id) external view returns (ReadonlyPointsCampaign memory campaign);

    /// @notice Returns a rewards based campaign in readonly format.
    /// @param id The wanted campaign id.
    /// @return campaign The rewards based campaign in readonly format.
    function rewardsCampaignById(bytes32 id) external view returns (ReadonlyRewardsCampaign memory campaign);

    /// @notice Returns the reward amount for a campaign and a reward token.
    /// @param id The id of the campaign to query.
    /// @param token The reward token to query.
    /// @return reward The reward amount.
    function campaignReward(bytes32 id, address token) external view returns (uint256 reward);

    /// @notice Returns the amount of claimed reward token for a campaign and a user.
    /// @param id The id of the campaign to query.
    /// @param token The reward token to query.
    /// @param account The claimer account.
    /// @return claimed The claimed amount.
    function claimedCampaignReward(bytes32 id, address token, address account)
        external
        view
        returns (uint256 claimed);

    /// @notice Creates one or more campaigns. The transaction will revert even if one
    /// of the specified bundles results in a creation failure (all or none).
    /// @param rewardsCampaignBundles The bundles containing the data used to create new rewards
    /// based campaigns.
    /// @param pointsCampaignBundles The bundles containing the data used to create new points
    /// based campaigns.
    function createCampaigns(
        CreateRewardsCampaignBundle[] calldata rewardsCampaignBundles,
        CreatePointsCampaignBundle[] calldata pointsCampaignBundles
    ) external;

    /// @notice Distributes rewards on one or more campaigns. The transaction will revert
    /// even if only one of the specified bundles results in a distribution failure (all or none).
    /// @param bundles The bundles containing the data used to distribute the rewards.
    function distributeRewards(DistributeRewardsBundle[] calldata bundles) external;

    /// @notice Sets the minimum rates for both reward and fee tokens.
    /// @param rewardTokenBundles The bundles containing the data used to update the minimum whitelisted
    /// reward token rates.
    /// @param feeTokenBundles The bundles containing the data used to update the minimum fee token rates.
    function setMinimumTokenRates(
        SetMinimumTokenRateBundle[] calldata rewardTokenBundles,
        SetMinimumTokenRateBundle[] calldata feeTokenBundles
    ) external;

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
    /// @param updater The new updater address.
    function setUpdater(address updater) external;

    /// @notice Can be called by Metrom's owner to set a new fee value.
    function setFee(uint32 fee) external;

    /// @notice Can be called by Metrom's owner to set a new specific protocol fee
    /// rebate for an account.
    /// @param account The account for which to set the rebate value.
    /// @param rebate The rebate.
    function setFeeRebate(address account, uint32 rebate) external;

    /// @notice Can be called by Metrom's owner to set a new minimum allowed campaign duration.
    /// @param minimumCampaignDuration The new minimum allowed campaign duration.
    function setMinimumCampaignDuration(uint32 minimumCampaignDuration) external;

    /// @notice Can be called by Metrom's owner to set a new maximum allowed campaign duration.
    /// @param maximumCampaignDuration The new maximum allowed campaign duration.
    function setMaximumCampaignDuration(uint32 maximumCampaignDuration) external;
}
