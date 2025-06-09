pragma solidity 0.8.28;

import {Metrom} from "../src/Metrom.sol";
import {Test} from "forge-std/Test.sol";
import {IMetrom, ClaimRewardBundle, DistributeRewardsBundle, RewardAmount} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract ClaimRewardsTest is Test {
    function testClaimFork1() public {
        // Mantle Sepolia
        vm.createSelectFork("https://mantle-sepolia.gateway.tenderly.co/6YPb43X3p0UkCBhUxnDOtC");

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

    // function testClaimFork2() public {
    //     // Holesky
    //     vm.createSelectFork("https://holesky.gateway.tenderly.co/6VWmszvurzDvGaJvxxMqe1");

    //     IMetrom _metrom = IMetrom(0xE2461a09B782efF63a2B50964a6DA3C15dD2A51e);
    //     address _metromImplementation = address(0x44508abbfD36325E35530849f77411030F9FDAfb);

    //     vm.etch(_metromImplementation, address(new Metrom()).code);

    //     address _account = address(0x06426F291E1D3F0E2298879aF90F4F937267386B);

    //     bytes32[] memory _proof = new bytes32[](3);
    //     _proof[0] = bytes32(0x5d60bf030f2e46ab3dd5d60cedfd2a8a6376158424f8f061f16bc45270133c3f);
    //     _proof[1] = bytes32(0x73cc50b4020115f50731733077faa3b16c7b1979d63e138994617aec8267ba92);
    //     _proof[2] = bytes32(0x7adae75a5bd9deca455ce01bdf557f89eb21a4e1f58546e09e7347232ef57dde);

    //     ClaimRewardBundle[] memory _bundles = new ClaimRewardBundle[](1);
    //     _bundles[0] = ClaimRewardBundle({
    //         campaignId: bytes32(0x0ba9e502617ac40f59b418ea2e4481aedef8637578bf4107b300f5935786a6e6),
    //         proof: _proof,
    //         token: address(0x0Fe5A93b63ACcf31679321dd0Daf341c037A1187),
    //         amount: 421004200249717501,
    //         receiver: _account
    //     });

    //     vm.startPrank(_account);
    //     _metrom.claimRewards(_bundles);
    // }
}
