# Contributing

Metrom contracts are developed using Foundry, so in order to contribute you need
to first install Foundry on your machine.
[Get Foundry here](https://book.getfoundry.sh/getting-started/installation).

Foundry manages dependencies using git submodules, so it's advised to use
`git clone --recurse-submodules` when cloning the repo in order to have a
ready-to-go environment. If git clone was used without the
`--recurse-submodules` flag, you can just run
`git submodule update --init --recursive` in the cloned repo in order to easily
install the dependencies.

The repository also uses some Javascript to manage a few parts of the
development lifecycle, so you should also run `pnpm install` in the repo to make
sure all the dependencies are installed. If you don't have `pnpm` on your
machine, you can [get it here](https://pnpm.io/installation).

After having done the above, the environment should be ready.

## Profiles

Profiles can be used in Foundry to specify different build configurations to
fine-tune the development process. Here we use 2 profiles:

- `default`: this default profile pretty much skips all the optimizations and
  focuses on raw performance. This is used during development to run all the
  available tests in a quick way, and without pointless optimizations.
- `production`: The production profile must be used when deploying contracts in
  production. This profile achieves maximum optimization leveraging the Yul IR
  optimizer. Depending on your machine, building with this profile can take some
  time.

All the profiles above are specified in the `foundry.toml` file at the root of
the project.

## Testing

Tests are written in Solidity and you can find them in the `tests` folder. We
write both property-based fuzzing and standard unit tests and easily execute
them through Foundry.

## Github Actions

The repository uses GH actions to setup CI to automatically run all the
available tests on each push.

## Pre-commit hooks

In order to reduce the mistakes risk to the minimum and maximize consistency,
pre-commit hooks are enabled to both run all the available tests (through the
same command used in the GH actions) and to lint the commit message through
`husky` and `@commitlint/config-conventional`.

Please have a look at the supported formats by checking
[this](https://github.com/conventional-changelog/commitlint/tree/master/@commitlint/config-conventional)
out.

### Deploying

> [!IMPORTANT]  
> The codebase relies on `solc` v0.8.25, however note that Solidity v0.8.20
> introduced a fundamental change, making `shanghai` the default EVM version.
> Shanghai introduced a new `PUSH0` opcode that will be present in the bytecode
> by default and might make the contract straight up not work correctly in
> chains that do not support Shanghai yet. In order to mitigate this, Paris has
> been set as the default target EVM version of the project in `foundry.toml`.
> However, Paris won't leverage the new `PUSH0` opcode, which can result in
> higher gas usage on chains that do indeed support it. Therefore, when
> deploying on a new network, if it supports Shanghai, make sure to leverage the
> `PUSH0` opcode by manually setting the targeted EVM version of the deployment
> through the `--evm-version` command flag or the `FOUNDRY_EVM_VERSION` env
> variable.

In order to deploy the whole platform to a given network you can go ahead and
create a .env.<NETWORK_NAME> file exporting the following env variables:

```
export PRIVATE_KEY=""
export RPC_URL=""
export OWNER=""
export UPDATER=""
export FEE_RECEIVER=""
export FEE=""
export ETHERSCAN_API_KEY=""
export VERIFIER_URL=""
```

Brief explainer of the env variables:

- `PRIVATE_KEY`: the private key of the account that will perform the
  deployment.
- `RPC_URL`: the RPC endpoint that will be used to broadcast transactions. This
  will also determine the network where the deployed contracts will reside.
- `OWNER`: the address that will own the deployed contracts and that will be
  able to set the protocol parameters.
- `UPDATER`: the address that will be allowed to update the Merkle roots for
  active campaigns and whitelisted token address rates.
- `FEE`: the fee to charge on campaigns creation, in points per million.
- `MINIMUM_CAMPAIGN_DURATION`: the minimum allowed campaign duration in seconds.
- `ETHERSCAN_API_KEY`: the Etherscan (or Blockscout) API key used to verify
  contracts.
- `VERIFIER_URL`: the Etherscan or Blockscout API URL that will be used to
  verify contracts.

Once you have one instance of this file for each network you're interested in
(e.g. .`env.sepolia`, `.env.gnosis`, `env.mainnet` etc etc), you can go ahead
and locally load the env variables by executing `source .env.<NETWORK_NAME>`.
After doing that, you can finally execute the following command to initiate the
deployment:

```
FOUNDRY_PROFILE=production forge script --broadcast --rpc-url $RPC_URL --sig 'run(address,address,uint32,uint32,uint32)' --verify Deploy $OWNER $UPDATER $GLOBAL_FEE $MINIMUM_CAMPAIGN_DURATION $MAXIMUM_CAMPAIGN_DURATION
```

### Addresses

Official addresses and creation blocks are tracked in the `index.ts` file and
are consumable from Javascript through a dedicated NPM package
(`@metrom-xyz/contracts`).
