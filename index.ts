import type { ChainContract } from "viem";
import { holesky } from "viem/chains";

export enum Environment {
    Development = "development",
    Staging = "staging",
}

export enum SupportedChain {
    Holesky = holesky.id,
}

export const ADDRESS: Record<
    Environment,
    Record<SupportedChain, ChainContract>
> = {
    [Environment.Development]: {
        [SupportedChain.Holesky]: {
            address: "0x2d2E7dC3c5CAD9020198b5FDDEc548cdBf079F68",
            blockCreated: 1823707,
        },
    },
    [Environment.Staging]: {
        [SupportedChain.Holesky]: {
            address: "0x2B428A243Af4ce5fF4E25a4E392708A4A020d28C",
            blockCreated: 1823713,
        },
    },
};
