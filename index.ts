import { type ChainContract } from "viem";
import {
    holesky,
    celoAlfajores,
    mantleSepoliaTestnet,
    mode,
} from "viem/chains";

export enum Environment {
    Development = "development",
    Staging = "staging",
    Production = "production",
}

export enum SupportedChain {
    Holesky = holesky.id,
    CeloAlfajores = celoAlfajores.id,
    MantleSepolia = mantleSepoliaTestnet.id,
    Mode = mode.id,
}

export const ADDRESS: Record<
    Environment,
    Record<SupportedChain, ChainContract | undefined>
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
    },
    [Environment.Staging]: {
        [SupportedChain.Holesky]: {
            address: "0xd2C71C57645e62f60E20287d759b0F8054693783",
            blockCreated: 2189175,
        },
        [SupportedChain.CeloAlfajores]: {
            address: "0x8a5FEc616053539757f4a990948DBbF69b9C052e",
            blockCreated: 25798811,
        },
        [SupportedChain.MantleSepolia]: {
            address: "0xEc0B101CDC03ae65F78cF5477F2b9e0FaB9f2b28",
            blockCreated: 11430921,
        },
    },
    [Environment.Production]: {
        [SupportedChain.Mode]: {
            address: "0x3325a167DA3130D7788E41f614C725C11DcEb5E7",
            blockCreated: 12613427,
        },
    },
};
