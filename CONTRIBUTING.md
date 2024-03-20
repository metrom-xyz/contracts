## Profiles

Profiles can be used in Foundry to specify different build configurations to
fine-tune the development process. Here we use 2 profiles:

- `default`: this default profile pretty much skips all the optimizations and
  focuses on raw speed. This is used during development to run all the available
  tests in a quick way, and without pointless optimizations.
- `production`: The production profile must be used when deploying contracts in
  production. This profile achieves maximum optimization leveraging the Yul IR
  optimizer. Depending on your machine, building with this profile can take some
  time.

All the profiles above are specified in the `foundry.toml` file at the root of
the project.

## Testing

Tests are written in Solidity and you can find them in the `tests` folder. Both
property-based fuzzing and standard unit tests are easily supported through the
use of Foundry.

## Github Actions

The repository uses GH actions to setup CI to automatically run all the
available tests on each push.

## Pre-commit hooks

In order to reduce the ability to make mistakes to the minimum and maximize
consistency, pre-commit hooks are enabled to both run all the available tests
(through the same command used in the GH actions) and to lint the commit message
through `husky` and `@commitlint/config-conventional`.

Please have a look at the supported formats by checking
[this](https://github.com/conventional-changelog/commitlint/tree/master/@commitlint/config-conventional)
out.

### Deploying

In order to deploy the whole platform to a given network you can go ahead and
create a .env.<NETWORK_NAME> file exporting 3 env variables:

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

- `PRIVATE_KEY`: the private key related to the account that will perform the
  deployment.
- `RPC_URL`: the RPC endpoint that will be used to broadcast transactions. This
  will also determine the network where the deployment will happen.
- `OWNER`: the address that will own the deployed core protocol contracts and
  that will be able to set some protocol parameters.
- `UPDATER`: the address that will be allowed to update Merkle trees for the
  campaigns.
- `FEE_RECEIVER`: the address of the fee receiver. This address will collect all
  the protocol fees.
- `FEE`: the basis points fee to charge on campaigns creation.
- `ETHERSCAN_API_KEY`: the Etherscan (or Blockscout) API key used to verify
  contracts.
- `VERIFIER_URL`: the Etherscan pr Blockscout API URL that will be used to
  verify contracts.

Once you have one instance of this file for each network you're interested in
(e.g. .`env.sepolia`, `.env.gnosis`, `env.mainnet` etc etc), you can go ahead
and locally load the env variables by executing `source .env.<NETWORK_NAME>`.
After doing that, you can finally execute the following command to initiate the
deployment:

```
// to verify on etherscan
FOUNDRY_PROFILE=production forge script --broadcast --rpc-url $RPC_URL --sig 'run(address,address,address,uint32)' --verify Deploy $OWNER $UPDATER $FEE_RECEIVER $FEE

// if you instead want to verify on blockscout
FOUNDRY_PROFILE=production forge script --broadcast --rpc-url $RPC_URL --sig 'run(address,address,address,uint32)' --verify --verifier blockscout --verifier-url $BLOCKSCOUT_INSTANCE_URL/api? Deploy $OWNER $UPDATER $FEE_RECEIVER $FEE
```

### Addresses

Official deployments and addresses are generally tracked in the `index.ts` file
and are consumable from Javascript through a dedicated NPM package.
