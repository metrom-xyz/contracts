pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {MAX_FEE} from "../src/Metrom.sol";
import {IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract BaseTest is Test {
    address internal owner;
    address internal updater;
    uint32 internal fee;
    uint32 internal minimumCampaignDuration;
    MetromHarness internal metrom;

    function setUp() external {
        owner = address(1);
        updater = address(2);
        fee = 10_000;
        minimumCampaignDuration = 5 seconds;
        metrom = new MetromHarness(owner, updater, fee, minimumCampaignDuration);
    }
}
