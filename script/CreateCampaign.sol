pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {UNIT, IMetrom, CreateBundle, RewardAmount} from "../src/IMetrom.sol";
import {IERC20} from "oz/token/ERC20/IERC20.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract CreateCampaign is Script {
    function run(
        address _metrom,
        uint256 _chainId,
        address _pool,
        uint32 _from,
        uint32 _to,
        bytes32 _specification,
        address _rewardToken,
        uint256 _rewardAmount
    ) public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        RewardAmount[] memory _rewards = new RewardAmount[](1);
        _rewards[0] = RewardAmount({token: _rewardToken, amount: _rewardAmount});

        CreateBundle memory _bundle = CreateBundle({
            chainId: _chainId,
            pool: _pool,
            from: _from,
            to: _to,
            specification: _specification,
            rewards: _rewards
        });

        CreateBundle[] memory _bundles = new CreateBundle[](1);
        _bundles[0] = _bundle;

        uint32 _fee = IMetrom(_metrom).fee();
        IERC20(_rewardToken).approve(_metrom, _rewardAmount + ((_rewardAmount * _fee) / UNIT));

        IMetrom(_metrom).createCampaigns(_bundles);

        vm.stopBroadcast();
    }
}
