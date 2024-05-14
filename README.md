<br />

<p align="center">
    <img src=".github/static/logo.svg" alt="Metrom logo" width="60%" />
</p>

<br />

<p align="center">
  Design your incentives to AMMplify liquidity.
</p>

<br />

<p align="center">
    <img src="https://img.shields.io/badge/License-GPLv3-blue.svg" alt="License: GPL v3">
    <img src="https://github.com/metrom-xyz/contracts/actions/workflows/ci.yml/badge.svg" alt="CI">
</p>

# Metrom contracts

The smart contract powering Metrom's efficient AMM incentivization. Both the
contracts and the tests are written in Solidity using Foundry.

## What is Metrom

Metrom is a tool that dexes (especially those based on concentrated liquidity
AMMs) can use to incentivize liquidity providers to provide the maximum amount
of liquidity possible in the way that is the most efficient through the creation
of dedicated incentivization campaigns.

Campaign creators can come to Metrom and create an incentivization campaign by
specifying a targeted pool, a running period, and a list of up to 5 rewards that
will be distributed to active LPs proportional to their liquidity contribution
in the pool. The incentivized pool can even live on a chain that is different
from the campaign's chain, making the product cross-chain.

Once a campaign is created and activated, Metrom's backend monitors the targeted
pool, processing all the meaningful on-chain event that happen on it and
computing a rewards distribution list off-chain depending on the specific
contribution of the various LPs. A Merkle tree is constructed from the list and
its root is then pushed on-chain. Eligible LPs can then claim their rewards (if
any) by simply providing a tree inclusion proof to the Metrom smart contract.

## Contributing

Want to contribute? Check out the [CONTRIBUTING.md](./CONTRIBUTING.md) file for
more info.
