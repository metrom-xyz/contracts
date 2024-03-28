pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {Clones} from "oz/proxy/Clones.sol";

import {MetromCampaign} from "../src/MetromCampaign.sol";
import {IMetromCampaignFactory, CreateCampaignParams} from "../src/interfaces/IMetromCampaignFactory.sol";
import {TokenAmount} from "../src/interfaces/IMetromCampaign.sol";
import {UNIT} from "../src/Commons.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract CreateCampaign is Script {
    function run(address _factory, address _pool, uint32 _from, uint32 _to, address _rewardToken, uint256 _rewardAmount)
        public
    {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        console2.log("From address:", address(this));

        TokenAmount[] memory _rewards = new TokenAmount[](1);
        _rewards[0] = TokenAmount({token: _rewardToken, amount: _rewardAmount});
        CreateCampaignParams memory _params =
            CreateCampaignParams({pool: _pool, from: _from, to: _to, rewards: _rewards});

        address _predictedCampaignAddress = IMetromCampaignFactory(_factory).predictCampaignAddress(_params);
        console2.log("Predicted campaign address:", _predictedCampaignAddress);

        uint32 _fee = IMetromCampaignFactory(_factory).fee();
        uint256 _amountPlusFees = _rewardAmount + (_rewardAmount * _fee / UNIT);
        console2.log("Approving reward:", _amountPlusFees);

        IERC20(_rewardToken).approve(_predictedCampaignAddress, _amountPlusFees);

        address _campaign = IMetromCampaignFactory(_factory).create(_params);
        console2.log("Campaign address: ", address(_campaign));

        vm.stopBroadcast();
    }
}
