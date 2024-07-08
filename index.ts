import { type ChainContract } from "viem";

export enum Environment {
    Development = "development",
    Staging = "staging",
}

export enum SupportedChain {
    Holesky = 17000,
    CeloAlfajores = 44787,
    LineaSepolia = 59141,
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
        [SupportedChain.LineaSepolia]: {
            address: "0xe82c4D8b993D613a28600B953e91A3A93Ae69Fd6",
            blockCreated: 2366812,
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
        [SupportedChain.LineaSepolia]: {
            address: "0x3325a167DA3130D7788E41f614C725C11DcEb5E7",
            blockCreated: 2366828,
        },
    },
};
