pragma solidity 0.8.28;

import {console2} from "forge-std/console2.sol";
import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";

import {IMetrom, RewardAmount, CreateRewardsCampaignBundle, CreatePointsCampaignBundle} from "../IMetrom.sol";

contract AmmPoolLiquidityRewardsCampaignCreator {
    using SafeERC20 for IERC20;

    IMetrom public metrom;

    constructor(IMetrom _metrom) {
        metrom = _metrom;
    }

    function create(uint32 from, uint32 to, RewardAmount[] calldata rewards, bytes32 poolId)
        external
        returns (bytes32)
    {
        CreateRewardsCampaignBundle memory _bundle = CreateRewardsCampaignBundle({
            from: from, to: to, kind: 1, data: abi.encode(poolId), specificationHash: bytes32(0), rewards: rewards
        });
        bytes32 _id = keccak256(
            abi.encode(
                address(this),
                _bundle.from,
                _bundle.to,
                _bundle.kind,
                _bundle.data,
                _bundle.specificationHash,
                _bundle.rewards
            )
        );

        CreateRewardsCampaignBundle[] memory _bundles = new CreateRewardsCampaignBundle[](1);
        _bundles[0] = _bundle;

        for (uint256 _i = 0; _i < rewards.length; _i++) {
            RewardAmount calldata _reward = rewards[_i];
            IERC20(_reward.token).safeTransferFrom(msg.sender, address(this), _reward.amount);
            IERC20(_reward.token).approve(address(metrom), _reward.amount);
        }

        IMetrom(metrom).createCampaigns(_bundles, new CreatePointsCampaignBundle[](0));
        IMetrom(metrom).transferCampaignOwnership(_id, msg.sender);

        // TODO: the caller should accept the ownership at this point

        return _id;
    }
}
