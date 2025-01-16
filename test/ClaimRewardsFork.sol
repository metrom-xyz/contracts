pragma solidity 0.8.28;

import {Metrom} from "../src/Metrom.sol";
import {Test} from "forge-std/Test.sol";
import {IMetrom, ClaimRewardBundle, DistributeRewardsBundle, RewardAmount} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract ClaimRewardsTest is Test {
    function setUp() external {
        vm.createSelectFork("https://rpc.tenderly.co/fork/81527808-e510-46b3-aa35-3bb7fee4a756");
    }

    function testClaimFork() public {
        IMetrom _metrom = IMetrom(0xB6044f769f519a634A5150645484b18d0C031ae8);
        address _metromImplementation = address(0x30c225e8c7795Ab56F271fb19087CF823c650C85);

        vm.etch(_metromImplementation, address(new Metrom()).code);

        address _account = address(0xc50275DAC18348425b7815BcdCC6dC82e0838CC5);

        bytes32[] memory _proof = new bytes32[](1);
        _proof[0] = bytes32(0xdf6b1e07defc342c1660c113f3853bd0abe453446f5796fa4286c850841a7838);

        ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
        _bundles[0] = ClaimRewardBundle({
            campaignId: bytes32(0x7bd4956b143b2e125b10358a84eed351f063e89f883b780dc93b2b7c53388bef),
            proof: _proof,
            token: address(0xD1D3Cf05Ef211C71056f0aF1a7FD1DF989E109c3),
            amount: 495000000000000000000,
            receiver: _account
        });

        vm.startPrank(_account);
        _metrom.claimRewards(_bundles);
    }
}
