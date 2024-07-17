import { type ChainContract } from "viem";

export enum Environment {
    Development = "development",
    Staging = "staging",
}

export enum SupportedChain {
    Holesky = 17000,
    CeloAlfajores = 44787,
    MantleSepolia = 5003,
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
        [SupportedChain.MantleSepolia]: {
            address: "0xe3dA4E4b76C4ed3e4227db20F20d1F25A4507f9b.",
            blockCreated: 9840417,
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
        [SupportedChain.MantleSepolia]: {
            address: "0xBbB06b25484AB9E23FEe8Ee321Af8e253ea7A76a",
            blockCreated: 9840495,
        },
    },
};
