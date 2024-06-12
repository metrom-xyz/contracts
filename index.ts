import type { ChainContract } from "viem";
import { holesky, celoAlfajores } from "viem/chains";

export enum Environment {
    Development = "development",
    Staging = "staging",
}

export enum SupportedChain {
    Holesky = holesky.id,
    CeloAlfajores = celoAlfajores.id,
}

export const ADDRESS: Record<
    Environment,
    Record<SupportedChain, ChainContract>
> = {
    [Environment.Development]: {
        [SupportedChain.Holesky]: {
            address: "0xd1c1153fd809Aae3bb431b586C032C4856abaeD4",
            blockCreated: 1715203,
        },
        [SupportedChain.CeloAlfajores]: {
            address: "0xDDD3e99f11488290Ff07BAe128Bd6D23362f2455",
            blockCreated: 24543646,
        },
    },
    [Environment.Staging]: {
        [SupportedChain.Holesky]: {
            address: "0x52015b596e765F7AA2668BCC30Fc715748A20A8e",
            blockCreated: 1719760,
        },
        [SupportedChain.CeloAlfajores]: {
            address: "0x8d98758EfF88Dc944035B0618a8412C400E71C72",
            blockCreated: 24556248,
        },
    },
};
