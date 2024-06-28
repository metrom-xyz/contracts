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
            address: "0x05B92b5C40a266EFDD8B3fDF0496407e8C0d9cB6",
            blockCreated: 1823746,
        },
        [SupportedChain.CeloAlfajores]: {
            address: "0x10E1A22034C5AF1E793c2Ac189b90ca47b252fF9",
            blockCreated: 24833828,
        },
    },
    [Environment.Staging]: {
        [SupportedChain.Holesky]: {
            address: "0x4A827f3Bf3c38Baa091DdCAb7B801aCee6819759",
            blockCreated: 1823756,
        },
        [SupportedChain.CeloAlfajores]: {
            address: "0xd1c1153fd809Aae3bb431b586C032C4856abaeD4",
            blockCreated: 24833840,
        },
    },
};
