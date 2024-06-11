pragma solidity 0.8.26;

import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {Initializable} from "oz-up/proxy/utils/Initializable.sol";

import {MetromHarness} from "./harnesses/MetromHarness.sol";
import {BaseTest} from "./Base.t.sol";
import {MAX_FEE, IMetrom} from "../src/IMetrom.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
contract InitializeTest is BaseTest {
    function test_failOnLogicContractDirectly() public {
        MetromHarness _metrom = new MetromHarness();
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        _metrom.initialize(address(1), address(1), address(1), 10, 10, 11);
    }

    function test_failInvalidOwner() public {
        MetromHarness _metrom = MetromHarness(address(new ERC1967Proxy(address(new MetromHarness()), bytes(""))));
        vm.expectRevert(IMetrom.InvalidOwner.selector);
        _metrom.initialize(address(0), address(0), address(0), 10, 10, 10);
    }

    function test_failInvalidCampaignsUpdater() public {
        MetromHarness _metrom = MetromHarness(address(new ERC1967Proxy(address(new MetromHarness()), bytes(""))));
        vm.expectRevert(IMetrom.InvalidCampaignsUpdater.selector);
        _metrom.initialize(address(1), address(0), address(0), 10, 10, 10);
    }

    function test_failInvalidRatesUpdater() public {
        MetromHarness _metrom = MetromHarness(address(new ERC1967Proxy(address(new MetromHarness()), bytes(""))));
        vm.expectRevert(IMetrom.InvalidRatesUpdater.selector);
        _metrom.initialize(address(1), address(1), address(0), 10, 10, 10);
    }

    function test_failInvalidFee() public {
        MetromHarness _metrom = MetromHarness(address(new ERC1967Proxy(address(new MetromHarness()), bytes(""))));
        vm.expectRevert(IMetrom.InvalidFee.selector);
        _metrom.initialize(address(1), address(1), address(1), uint32(MAX_FEE + 1), 10, 10);
    }

    function test_failInvalidMinimumCampaignDuration() public {
        MetromHarness _metrom = MetromHarness(address(new ERC1967Proxy(address(new MetromHarness()), bytes(""))));

        // minimum campaign duration > than maximum campaign duration
        vm.expectRevert(IMetrom.InvalidMinimumCampaignDuration.selector);
        _metrom.initialize(address(1), address(1), address(1), uint32(10_000), 10, 8);

        _metrom = MetromHarness(address(new ERC1967Proxy(address(new MetromHarness()), bytes(""))));
        // minimum campaign duration == than maximum campaign duration
        vm.expectRevert(IMetrom.InvalidMinimumCampaignDuration.selector);
        _metrom.initialize(address(1), address(1), address(1), uint32(10_000), 10, 10);
    }

    function test_success() public {
        address _owner = address(1);
        address _campaignsUpdater = address(2);
        address _ratesUpdater = address(3);
        uint32 _fee = 10;
        uint32 _minimumCampaignDuration = 5 seconds;
        uint32 _maximumCampaignDuration = 10 seconds;

        MetromHarness _metrom = MetromHarness(address(new ERC1967Proxy(address(new MetromHarness()), bytes(""))));

        vm.expectEmit();
        emit IMetrom.Initialize(
            _owner, _campaignsUpdater, _ratesUpdater, _fee, _minimumCampaignDuration, _maximumCampaignDuration
        );

        _metrom.initialize(
            _owner, _campaignsUpdater, _ratesUpdater, _fee, _minimumCampaignDuration, _maximumCampaignDuration
        );

        vm.assertEq(_metrom.owner(), _owner);
        vm.assertEq(_metrom.pendingOwner(), address(0));
        vm.assertEq(_metrom.campaignsUpdater(), _campaignsUpdater);
        vm.assertEq(_metrom.ratesUpdater(), _ratesUpdater);
        vm.assertEq(_metrom.fee(), _fee);
        vm.assertEq(_metrom.minimumCampaignDuration(), _minimumCampaignDuration);
        vm.assertEq(_metrom.maximumCampaignDuration(), _maximumCampaignDuration);
    }

    function testFuzz_success(
        address _owner,
        address _campaignsUpdater,
        address _ratesUpdater,
        uint32 _fee,
        uint32 _rawMinimumCampaignDuration,
        uint32 _maximumCampaignDuration
    ) public {
        vm.assume(_owner != address(0));
        vm.assume(_campaignsUpdater != address(0));
        vm.assume(_ratesUpdater != address(0));
        vm.assume(_fee <= MAX_FEE);
        vm.assume(_maximumCampaignDuration > 0);
        uint32 _minimumCampaignDuration = uint32(bound(_rawMinimumCampaignDuration, 0, _maximumCampaignDuration - 1));

        MetromHarness _metrom = MetromHarness(address(new ERC1967Proxy(address(new MetromHarness()), bytes(""))));

        vm.expectEmit();
        emit IMetrom.Initialize(
            _owner, _campaignsUpdater, _ratesUpdater, _fee, _minimumCampaignDuration, _maximumCampaignDuration
        );

        _metrom.initialize(
            _owner, _campaignsUpdater, _ratesUpdater, _fee, _minimumCampaignDuration, _maximumCampaignDuration
        );

        vm.assertEq(_metrom.owner(), _owner);
        vm.assertEq(_metrom.pendingOwner(), address(0));
        vm.assertEq(_metrom.campaignsUpdater(), _campaignsUpdater);
        vm.assertEq(_metrom.ratesUpdater(), _ratesUpdater);
        vm.assertEq(_metrom.fee(), _fee);
        vm.assertEq(_metrom.minimumCampaignDuration(), _minimumCampaignDuration);
        vm.assertEq(_metrom.maximumCampaignDuration(), _maximumCampaignDuration);
    }
}
