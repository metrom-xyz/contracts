import { type ChainContract } from "viem";

export enum Environment {
    Development = "development",
    Production = "production",
}

export enum SupportedChain {
    Holesky = 17_000,
    CeloAlfajores = 44_787,
    MantleSepolia = 5_003,
    SonicTestnet = 64165,

    Mode = 34_443,
    Mantle = 5_000,
}

export const ADDRESS: Record<
    Environment,
    { [chainId: number]: ChainContract | undefined }
> = {
    [Environment.Development]: {
        [SupportedChain.Holesky]: {
            address: "0xE2461a09B782efF63a2B50964a6DA3C15dD2A51e",
            blockCreated: 2189164,
        },
        [SupportedChain.CeloAlfajores]: {
            address: "0x0Fe5A93b63ACcf31679321dd0Daf341c037A1187",
            blockCreated: 25798782,
        },
        [SupportedChain.MantleSepolia]: {
            address: "0xB6044f769f519a634A5150645484b18d0C031ae8",
            blockCreated: 11430844,
        },
        [SupportedChain.SonicTestnet]: {
            address: "0xD4AC4AaFb81eC774E49AA755A66EfCe4574D6276",
            blockCreated: 73294873,
        },
    },
    [Environment.Production]: {
        [SupportedChain.Mode]: {
            address: "0xc325890958D399ee26c26D21bBeFbDA17B03a611",
            blockCreated: 12904333,
        },
        [SupportedChain.Mantle]: {
            address: "0x4300d4C410f87c7c1824Cbc2eF67431030106604",
            blockCreated: 68933021,
        },
    },
};
